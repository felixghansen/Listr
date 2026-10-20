import FirebaseAI
import AppKit

struct PostcardAnalyzer {
    private let model: GenerativeModel
    
    private static let responseSchema = Schema.array(items: .object(properties: [
        "title": .string(),
        "description": .string(),
        "era": .enumeration(values: EbayAspectValues.era),
        "type": .object(properties: [
            "material": .enumeration(values: EbayAspectValues.material),
            "style": .enumeration(values: EbayAspectValues.style)
        ]),
        "publisher": .string(),
        "keywords": .array(items: .string()),
        "condition": .string(),
        "postmarkDate": .string(),
        "mailingOrigin": .string(),
        "ebayCategoryID": .integer(),
        "suggestedPrice": .object(properties: [
            "price": .double(),
            "auctionStart": .double()
        ])
    ]))
    
    init() {
        model = FirebaseAI
            .firebaseAI(backend: .googleAI())
            .generativeModel(
                modelName: "gemini-2.5-flash",
                generationConfig: GenerationConfig(
                    responseMIMEType: "application/json",
                    responseSchema: Self.responseSchema
                )
            )
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
    
    // TODO: Make prompt return more accurate results. Concise details. Avoid fluff in description. Try to find a solution to pricing. It will almost always be inaccurate. If we remove it, then every postcard wont be ready to list... 
    private var prompt: String {
        """
        Act as a professional vintage postcard dealer and expert eBay listing creator specializing in collectible postcards.
        You will analyze postcards provided as FRONT and BACK image pairs (images 1–2 = postcard A, 3–4 = postcard B, etc.) and return one object per postcard.

        Write the way top eBay postcard sellers do: concise, keyword-rich titles, factual descriptions, and realistic prices.

        VALUE INDICATORS
        Consider these traits when pricing and writing the title, and mention them in the title and description when clearly evident:
        - Real Photo Postcards (RPPCs)
        - Small or obscure town views
        - Artist-signed cards (e.g., Ellen Clapsaddle, Frances Brundage, Samuel Schmucker)
        - Notable publishers (e.g., Raphael Tuck & Sons, Detroit Publishing)
        - Transportation scenes (trains, trams, automobiles, airplanes, ships)
        - Disasters (fires, floods, earthquakes)
        - Military, naval, or aviation themes
        - Identifiable landmarks, signage, or businesses
        - Early dated postmarks (pre-1920)
        - Hand-tinted or colorized RPPCs
        - Social or occupational scenes (farming, logging, factory work)

        GENERAL RULES
        - Capitalize proper nouns.
        - For era, material, and style: if you are not reasonably sure, choose "Unknown". A wrong value is worse than "Unknown", because the seller reviews every Unknown field before listing.

        FIELD INSTRUCTIONS
        1. title
        Concise, SEO-optimized eBay title. Max 80 characters. Exclude condition words. Put location or topic first.
        Use English place names (e.g., Nuremberg, Munich, Cologne, Florence) and include the country for places outside the US. Add the local-language name only if space allows.
        Include the strongest value indicator visible on the card (e.g., Tram, Automobile, RPPC, artist name).
        Pattern: [Location or Topic] [Subject] [Value Indicator] [RPPC/Linen/Chrome if relevant] [UB/DB/WB if relevant] [circa decade]
        Examples:
        New York City Empire State Building RPPC c1930s
        Niagara Falls Horseshoe Falls Linen Postcard c1950s
        Nuremberg Germany St Lorenz Church Tram Franz Schmitz Artist DB c1910s
        Ellen Clapsaddle Halloween Children DB c1910s
        WWI Soldiers in Trenches France RPPC c1915

        2. description
        Factual collector-style description, 2–4 sentences, covering subject, location, approximate date, card type, publisher, and postmark. Mention condition briefly without repeating the condition field word for word. No filler or sales language.
        Example:
        Vintage real photo postcard showing the Empire State Building, New York City, c1930s. Published by Curt Teich. Unposted.

        3. era
        Choose one of:
        - \(EbayAspectValues.era.joined(separator: "\n- "))
        First decide whether the card is European (published in Europe or showing a European place).
        - If European, you MUST use a "Europe Era" value based on the estimated date, even if the back style matches another period.
        - If not European, use the period matching the card's printing and back.
        Use "Real Photo (1900-Now)" only for a non-European real photo card whose date can't be narrowed down.

        4. type
        material: the card's type, one of \(EbayAspectValues.material.joined(separator: ", ")).
        Choose in this order of priority: Real Photo (RPPC) if it is a real photograph; otherwise Artist Card if it is artist-signed; otherwise the printing type.
        style: the back type, one of \(EbayAspectValues.style.joined(separator: ", ")).

        5. publisher
        The publisher’s name only, as printed on the card. Exclude addresses, cities, printer credits, and parenthetical notes. Max 65 characters. Use "Unknown" if none.

        6. keywords
        3–6 collector search terms not already in the title (e.g., Streetcar, Bridge, Automobile). Include common synonyms buyers search for (e.g., Tram and Streetcar).

        7. condition
        Short factual summary of physical condition only (e.g., "Minor corner wear", "Crease along left edge"). Do not mention whether it was posted.

        8. postmarkDate
        Format YYYY-MM-DD, or "Unposted" if there is no postmark.

        9. mailingOrigin
        Postmark city and state, or city and country, or "Unposted".

        10. ebayCategoryID
        262042 (Topographical) if the card mainly shows a real, identifiable place; 262043 (Non-Topographical) for everything else. For cards with crossover appeal, pick the category whose collectors would be more interested in this specific card.

        11. suggestedPrice
        Price in US dollars (USD). Estimate based on typical market values for similar cards, using these ranges as anchors:
        - Common Chrome scenic: $3–8
        - Linen or White Border with regional appeal: $8–15
        - Good RPPC (clear, small-town, or event): $15–40
        - Strong RPPC (rare town, disaster, or transportation): $40–100+
        - Artist-signed or themed (Halloween, WWI, Santa, etc.): $15–100 for typical examples; $100–400+ only for rare or exceptional cards
        Set auctionStart to 25–50% of price.
        """
    }
}
