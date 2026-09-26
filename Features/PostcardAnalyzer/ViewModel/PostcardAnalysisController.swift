import Foundation
import AppKit

@MainActor
final class PostcardAnalysisController: ObservableObject {
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var totalImages = 0
    @Published var imagesAnalyzed = 0

    private let analyzer = PostcardAnalyzer()
    private let decoder = JSONDecoder()
    private let imageExtensions = ["jpg", "jpeg", "png"]

    // Images sent to the AI per request: 3 postcards, front + back
    private let imagesPerRequest = 6

    private var analysisTask: Task<Void, Never>?

    func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let folderURL = panel.url {
            analyzeFolder(folderURL)
        }
    }

    func analyzeFolder(_ folderURL: URL) {
        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            await self?.runAnalysis(folderURL)
        }
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isAnalyzing = false
    }
    

    private func runAnalysis(_ folderURL: URL) async {
        do {
            let imageFiles = try FileManager.default
                .contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                .filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            guard !imageFiles.isEmpty else {
                errorMessage = "No valid images found in folder."
                return
            }

            totalImages = imageFiles.count
            imagesAnalyzed = 0
            errorMessage = nil
            isAnalyzing = true

            let batchID = BatchRepository.shared.createNewBatchID()

            // Split the files into groups, one AI request per group
            let imageGroups = stride(from: 0, to: imageFiles.count, by: imagesPerRequest).map {
                Array(imageFiles[$0..<min($0 + imagesPerRequest, imageFiles.count)])
            }

            try await withThrowingTaskGroup(of: (json: String, imageGroup: [URL]).self) { taskGroup in
                for imageGroup in imageGroups {
                    taskGroup.addTask {
                        try Task.checkCancellation()
                        let images = imageGroup.compactMap { NSImage(contentsOf: $0) }
                        let json = try await self.analyzer.analyzePostcardImages(images: images)
                        return (json, imageGroup)
                    }
                }

                for try await result in taskGroup {
                    try Task.checkCancellation()
                    await saveResult(result.json, imageGroup: result.imageGroup, batchID: batchID)
                }
            }
        } catch is CancellationError {
            // Cancelled by the user, nothing to report
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    private func saveResult(_ json: String, imageGroup: [URL], batchID: String) async {
        do {
            let aiResults = try decoder.decode([PostcardAIData].self, from: Data(json.utf8))
            let postcards = await createPostcards(from: aiResults, imageGroup: imageGroup, batchID: batchID)
            try await PostcardRepository.shared.savePostcards(postcards, toBatch: batchID)

            imagesAnalyzed = min(imagesAnalyzed + postcards.count * 2, totalImages)
        } catch {
            print("Saving analysis result failed: \(error)")
            errorMessage = "Couldn't save some postcards: \(error.localizedDescription)"
        }
    }

    // Pairs each AI result with its front and back image, uploads the images, and builds the postcard
    private func createPostcards(from aiResults: [PostcardAIData], imageGroup: [URL], batchID: String) async -> [PostcardDetails] {
        var postcards: [PostcardDetails] = []

        for (index, aiData) in aiResults.enumerated() {
            let frontIndex = index * 2

            guard frontIndex + 1 < imageGroup.count,
                  let frontImage = NSImage(contentsOf: imageGroup[frontIndex]),
                  let backImage = NSImage(contentsOf: imageGroup[frontIndex + 1]) else {
                print("Skipped postcard \(index): missing or unreadable image pair")
                continue
            }

            do {
                // upload postcards to firebase
                let postcardID = UUID().uuidString
                let frontURL = try await StorageManager.shared.uploadImage(frontImage, batchID: batchID, fileName: "\(postcardID)_front.jpg")
                let backURL = try await StorageManager.shared.uploadImage(backImage, batchID: batchID, fileName: "\(postcardID)_back.jpg")

                let postcard = PostcardDetails(
                    batchID: batchID,
                    scannedAt: Date(),
                    frontImageURLString: frontURL,
                    backImageURLString: backURL,
                    aiData: aiData
                )
                postcards.append(postcard)
            } catch {
                print("Image upload failed for postcard \(index): \(error)")
            }
        }

        return postcards
    }
}
