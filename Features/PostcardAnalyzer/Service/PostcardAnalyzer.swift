import FirebaseAI
import AppKit

struct PostcardAnalyzer {
    private let model: GenerativeModel
    
    init() {
        model = FirebaseAI
            .firebaseAI(backend: .googleAI())
            .generativeModel(modelName: "gemini-2.5-flash")
    }
    
    enum PostcardAnalysisError: Error {
        case insufficientImages
        case noTextGenerated
    }
    
    func analyzePostcardImages(images: [NSImage]) async throws -> String {
        guard !images.isEmpty else {
            throw PostcardAnalysisError.insufficientImages
        }

        let usedImages = Array(images.prefix(6))
        
        let responseText: String?
        
        let start = Date()
        
        switch usedImages.count {
            case 1:
                let res = try await model.generateContent(usedImages[0], prompt)
                responseText = res.text
            case 2:
                let res = try await model.generateContent(usedImages[0], usedImages[1], prompt)
                responseText = res.text
            case 3:
                let res = try await model.generateContent(usedImages[0], usedImages[1], usedImages[2], prompt)
                responseText = res.text
            case 4:
                let res = try await model.generateContent(usedImages[0], usedImages[1], usedImages[2], usedImages[3], prompt)
                responseText = res.text
            case 5:
                let res = try await model.generateContent(usedImages[0], usedImages[1], usedImages[2], usedImages[3], usedImages[4], prompt)
                responseText = res.text
            case 6:
                let res = try await model.generateContent(usedImages[0], usedImages[1], usedImages[2], usedImages[3], usedImages[4], usedImages[5], prompt)
                responseText = res.text
            default:
                let res = try await model.generateContent(prompt)
                responseText = res.text
        }

        let elapsed = Date().timeIntervalSince(start)
        print("Time to generate: \(elapsed) seconds")
        
        guard let responseText = responseText else {
            throw PostcardAnalysisError.noTextGenerated
        }

        let text = cleanJSONString(responseText)

        guard !text.isEmpty else {
            throw PostcardAnalysisError.noTextGenerated
        }

        return text
    }
    
    private func cleanJSONString(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            
        if cleaned.hasPrefix("```") {
            if let range = cleaned.range(of: "```.*?\n", options: [.regularExpression]) {
                cleaned.removeSubrange(range)
            }
        }
        
        if let range = cleaned.range(of: "```", options: .backwards) {
            cleaned.removeSubrange(range)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var prompt: String {
        """
        Act as a professional vintage postcard dealer and expert eBay listing creator specializing in collectible postcards.
        You will analyze multiple postcards (each consisting of FRONT and BACK image pairs — e.g., images 1–2 = postcard A, 3–4 = postcard B, etc.) and produce highly accurate, eBay-ready structured data.

        Your output must replicate how top eBay postcard sellers write — concise, keyword-rich titles, natural yet informative descriptions, and realistic pricing drawn from comparable market sales.

        VALUE INDICATORS
        Briefly note what may make a postcard more valuable. These traits should influence pricing and be included in the title if clearly identifiable.

        Potential high-value traits:
        - Real Photo Postcards (RPPCs)
        - Small or obscure town views
        - Artist-signed cards (e.g., Clapsaddle, Brundage, Schmucker, Tuck)
        - Transportation scenes (trains, automobiles, airplanes, ships)
        - Disasters (fires, floods, earthquakes)
        - Military, naval, or aviation themes
        - Identifiable landmarks, signage, or businesses
        - Early dated postmarks (pre-1920)
        - Hand-tinted or colorized RPPCs
        - Social or occupational scenes (farming, logging, factory work)

        Include these traits naturally in the title and description when evident.

        STRICT OUTPUT FORMAT
        1. Respond ONLY with a single JSON array — no explanations, commentary, or markdown formatting.
        2. Each array element = one complete postcard object.
        3. Capitalize all proper nouns (Title Case).
        4. Use numeric floats for prices (e.g., 8.50).
        5. If data is missing or unclear, use: "Unknown", "Unposted", or "None" as appropriate.
        6. All JSON keys must use camelCase exactly as shown below — this is critical for decoding into Swift.

        JSON SCHEMA (camelCase)
        {
            "title": "string",
            "description": "string",
            "era": "string",
            "type": {
                "material": "string",
                "style": "string"
            },
            "publisher": "string",
            "keywords": ["string"],
            "condition": "string",
            "postmarkDate": "string",
            "mailingOrigin": "string",
            "ebayCategoryID": 0,
            "suggestedPriceCAD": {
                "price": 0.00,
                "auctionStart": 0.00
            }
        }

        FIELD INSTRUCTIONS
        1. title
        Concise, SEO-optimized eBay title in the same style expert postcard dealers use.
        Max 80 characters. Exclude condition words. Include location or topic first.
        Follow this general pattern:
        [Location or Topic] [Subject] [Material Type if RPPC] [Style Type if relevant] [Era]
        Possible examples:
        New York City Empire State Building RPPC c1930s
        Niagara Falls Horseshoe Falls Linen Postcard c1950s
        Ellen Clapsaddle Halloween Children DB c1910s
        WWI Soldiers in Trenches France RPPC c1915

        2. description
        Short, factual collector-style description (2–4 sentences) including subject, location, era, type (both material and style), publisher, postmark, and condition.
        Example:
        Vintage real photo postcard showing the Empire State Building, New York City. RPPC, c1930s. Published by Curt Teich. Unposted with clean back and minor corner wear.

        3. era
        Estimated production decade or range (e.g., c1910s, c1940s).

        4. type
        Pick the postcard's material and style out of these possible options, "Unknown" if unknown.
        
        material: [RPPC, Linen, Chrome]
        style: [WB, UB, DB]

        5. publisher
        Printed publisher name if visible, else "Unknown".

        6. keywords
        3–6 collector search terms not already in the title (e.g., Streetcar, Bridge, Automobile).

        7. condition
        Short factual summary (Minor corner wear, Crease left edge, Unused).

        8. postmarkDate
        Format YYYY-MM-DD or Unposted.

        9. mailingOrigin
        Postmark city/state or city/country or Unposted.

        10. ebayCategoryID
        Exact numerical ID for postcard type, e.g., 173575 for Collectibles > Postcards > Topographical > United States > New York. Use 0 if unknown.

        11. PRICING LOGIC (CAD)
        "suggestedPriceCAD": { "price": 0.00, "auctionStart": 0.00 }

        Base pricing on rarity, subject, and condition — using comparable sold eBay listings.
        Guidelines:
        - Common Chrome scenic: $5–10
        - Linen or White Border with regional appeal: $10–20
        - Good RPPC (clear, small-town, or event): $20–50
        - Strong RPPC (rare town, disaster, or transportation): $50–150
        - Artist-signed or themed (Halloween, WWI, Santa, etc.): $100–400+

        Set auctionStart to 25–50% of price value.
        """
    }
}
