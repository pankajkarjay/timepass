import Foundation

final class KnowledgeStore {
    private let fileURL: URL

    init(filename: String = "knowledge_cards.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
    }

    func loadCards() throws -> [KnowledgeCard] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.iso8601.decode([KnowledgeCard].self, from: data)
    }

    func saveCards(_ cards: [KnowledgeCard]) throws {
        let data = try JSONEncoder.pretty.encode(cards)
        try data.write(to: fileURL, options: .atomic)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
