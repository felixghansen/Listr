import Foundation
import AppKit
import FirebaseFirestore

@MainActor
final class PostcardAnalysisController: ObservableObject {
    
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    @Published var totalImages: Int = 0
    @Published var imagesAnalyzed: Int = 0
    
    private let analyzer = PostcardAnalyzer()
    
    private let db = Firestore.firestore()
    private let decoder = JSONDecoder()
    private let imageExtensions = ["jpg", "jpeg", "png"]
    
    private let batchSize = 6 // 3 postcards (front + back)
    
    private var analysisTask: Task<Void, Never>?

    func analyzeFolder(_ folderURL: URL) async {
        // If something is already running, cancel it before starting a new one
        analysisTask?.cancel()

        analysisTask = Task { [weak self] in
            guard let self else { return }
            await self.runAnalysis(folderURL)
        }
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isAnalyzing = false
    }

    private func runAnalysis(_ folderURL: URL) async {
        do {
            try Task.checkCancellation()

            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            let imageFiles = files
                .filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            let images = imageFiles.compactMap { NSImage(contentsOf: $0) }
            guard !images.isEmpty else {
                await MainActor.run {
                    self.errorMessage = "No valid images found in folder."
                }
                return
            }

            await MainActor.run {
                self.totalImages = imageFiles.count
                self.imagesAnalyzed = 0
                self.isAnalyzing = true
                self.errorMessage = nil
            }

            let batchID = BatchRepository.shared.createNewBatchID()

            let batches = stride(from: 0, to: images.count, by: batchSize).map { index in
                Array(images[index..<min(index + batchSize, images.count)])
            }

            try await withThrowingTaskGroup(of: (String, Int).self) { group in
                for (index, batch) in batches.enumerated() {
                    try Task.checkCancellation()
                    group.addTask {
                        try Task.checkCancellation()
                        let jsonString = try await self.analyzer.analyzePostcardImages(images: batch)
                        return (jsonString, index)
                    }
                }

                for try await (jsonString, index) in group {
                    try Task.checkCancellation()
                    await self.handleAnalysisBatch(jsonString, index: index, batchID: batchID, imageFiles: imageFiles)
                }
            }
        } catch is CancellationError {
            // Swallow cancellation gracefully
        } catch {
            await MainActor.run {
                self.errorMessage = "Analysis failed: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            self.isAnalyzing = false
        }
    }
    
    func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let folderURL = panel.url {
            Task {
                await analyzeFolder(folderURL)
            }
        }
    }
    
    private func handleAnalysisBatch(_ jsonString: String, index: Int, batchID: String, imageFiles: [URL]) async {
        print("handleAnalysisBatch \(index)")
        guard let jsonData = jsonString.data(using: .utf8) else {
            let message = "Batch \(index): Failed to convert JSON string to Data."
            print("❌ [handleAnalysisBatch] \(message)")
            await MainActor.run { self.errorMessage = message }
            return
        }
        
        do {
            let extractedData = try decoder.decode([PostcardAIExtractedData].self, from: jsonData)
            
            let postcardDetails = await self.createPostcardDetails(
                from: extractedData,
                batchID: batchID,
                imageFiles: imageFiles,
                batchIndex: index
            )
            
            try await PostcardRepository.shared.savePostcards(postcardDetails, toBatch: batchID)
            
            await MainActor.run {
                self.imagesAnalyzed += postcardDetails.count * 2
                self.imagesAnalyzed = min(self.imagesAnalyzed, self.totalImages)
            }
        } catch {
            print("❌ [handleAnalysisBatch] JSON decoding or Firestore save failed for batch \(index): \(error)")
            await MainActor.run {
                self.errorMessage = "Batch \(index): JSON decoding failed - \(error.localizedDescription)"
            }
        }
    }
    
    private func createPostcardDetails(
        from aiResults: [PostcardAIExtractedData],
        batchID: String,
        imageFiles: [URL],
        batchIndex: Int
    ) async -> [PostcardDetails] {
        var details: [PostcardDetails] = []

        for (i, aiData) in aiResults.enumerated() {
            let baseIndex = (batchIndex * batchSize) + (i * 2)
            guard baseIndex + 1 < imageFiles.count else {
                print("⚠️ [createPostcardDetails] Skipped postcard at index \(i) — missing image pair.")
                continue
            }

            let frontLocalURL = imageFiles[baseIndex]
            let backLocalURL = imageFiles[baseIndex + 1]

            guard let frontImage = NSImage(contentsOf: frontLocalURL),
                  let backImage = NSImage(contentsOf: backLocalURL) else {
                print("⚠️ [createPostcardDetails] Failed to load images at index \(i).")
                continue
            }

            do {
                // Upload images to Firebase Storage
                let postcardID = UUID().uuidString
                let frontImageURL = try await StorageManager.shared.uploadImage(frontImage, batchID: batchID, fileName: "\(postcardID)_front.jpg")
                let backImageURL = try await StorageManager.shared.uploadImage(backImage, batchID: batchID, fileName: "\(postcardID)_back.jpg")

                let postcard = PostcardDetails(
                    batchID: batchID,
                    scannedAt: Date(),
                    frontImageURLString: frontImageURL,
                    backImageURLString: backImageURL,
                    aiData: aiData
                )
                

                details.append(postcard)
            } catch {
                print("❌ [createPostcardDetails] Upload failed for postcard at index \(i): \(error)")
                continue
            }
        }

        return details
    }

}
