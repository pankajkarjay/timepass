import Foundation

enum AppError: LocalizedError {
    case photoPermissionDenied
    case screenshotsAlbumNotFound
    case noScreenshots
    case imageLoadFailed
    case ocrFailed
    case missingAPIKey
    case invalidResponse
    case networkFailure(String)
    case storageFailure

    var errorDescription: String? {
        switch self {
        case .photoPermissionDenied:
            return "Photos permission denied. Please allow access in Settings."
        case .screenshotsAlbumNotFound:
            return "Could not find the Screenshots album."
        case .noScreenshots:
            return "No screenshots available to process."
        case .imageLoadFailed:
            return "Unable to load screenshot image data."
        case .ocrFailed:
            return "OCR failed for one or more screenshots."
        case .missingAPIKey:
            return "Missing OpenAI API key. Set OPENAI_API_KEY in your Run scheme."
        case .invalidResponse:
            return "AI service returned invalid data."
        case .networkFailure(let message):
            return "Network error: \(message)"
        case .storageFailure:
            return "Could not save or load local data."
        }
    }
}
