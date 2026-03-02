import Foundation

struct KnowledgeCard: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let sourceAssetLocalIdentifier: String
    let extractedText: String
    let classification: ClassificationResult
    var convertedNote: LocalNote?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        sourceAssetLocalIdentifier: String,
        extractedText: String,
        classification: ClassificationResult,
        convertedNote: LocalNote? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.sourceAssetLocalIdentifier = sourceAssetLocalIdentifier
        self.extractedText = extractedText
        self.classification = classification
        self.convertedNote = convertedNote
    }
}

struct ClassificationResult: Codable, Hashable {
    let type: String
    let title: String
    let summary: String
    let importantData: ImportantData
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case summary
        case importantData = "important_data"
        case tags
    }
}

struct ImportantData: Codable, Hashable {
    let amount: String
    let date: String
    let company: String
    let location: String
}

struct LocalNote: Codable, Hashable {
    let id: UUID
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}
