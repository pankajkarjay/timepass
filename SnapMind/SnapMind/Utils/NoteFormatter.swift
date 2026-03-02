import Foundation

enum NoteFormatter {
    static func makeNote(from card: KnowledgeCard) -> LocalNote {
        let c = card.classification
        let content = """
        # \(c.title)

        Type: \(c.type.capitalized)
        Summary: \(c.summary)

        Important Data
        - Amount: \(c.importantData.amount)
        - Date: \(c.importantData.date)
        - Company: \(c.importantData.company)
        - Location: \(c.importantData.location)

        Tags: \(c.tags.joined(separator: ", "))

        ---
        Raw OCR Text:
        \(card.extractedText)
        """

        return LocalNote(content: content)
    }
}
