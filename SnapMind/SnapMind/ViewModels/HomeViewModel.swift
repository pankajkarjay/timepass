import Foundation
import Photos

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var cards: [KnowledgeCard] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasPro = false

    private let freeLimit = 5
    private let photoScanner = PhotoScannerService()
    private let ocrService = OCRService()
    private let aiService = AIClassifierService()
    private let store = KnowledgeStore()

    var filteredCards: [KnowledgeCard] {
        guard !searchText.isEmpty else { return cards }
        return cards.filter {
            $0.classification.title.localizedCaseInsensitiveContains(searchText)
            || $0.classification.summary.localizedCaseInsensitiveContains(searchText)
            || $0.classification.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
        }
    }

    var canShowUpgradePrompt: Bool {
        !hasPro
    }

    func loadStoredCards() {
        do {
            cards = try store.loadCards().sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = AppError.storageFailure.localizedDescription
        }
    }

    func scanScreenshots() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let granted = await photoScanner.requestAccess()
        guard granted else {
            errorMessage = AppError.photoPermissionDenied.localizedDescription
            return
        }

        do {
            let limit = hasPro ? 100 : freeLimit
            let assets = try photoScanner.fetchRecentScreenshotAssets(limit: limit)

            var newCards: [KnowledgeCard] = []
            for asset in assets {
                if cards.contains(where: { $0.sourceAssetLocalIdentifier == asset.localIdentifier }) {
                    continue
                }

                let image = try await photoScanner.loadImage(for: asset)
                let extracted = try await ocrService.extractText(from: image)
                let classified = try await aiService.classifyText(extracted)

                let card = KnowledgeCard(
                    sourceAssetLocalIdentifier: asset.localIdentifier,
                    extractedText: extracted,
                    classification: classified
                )
                newCards.append(card)
            }

            cards = (newCards + cards).sorted { $0.createdAt > $1.createdAt }
            try store.saveCards(cards)
        } catch {
            let appError = error as? AppError
            errorMessage = appError?.localizedDescription ?? error.localizedDescription
        }
    }

    func convertToNote(card: KnowledgeCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index].convertedNote = NoteFormatter.makeNote(from: cards[index])

        do {
            try store.saveCards(cards)
        } catch {
            errorMessage = AppError.storageFailure.localizedDescription
        }
    }
}
