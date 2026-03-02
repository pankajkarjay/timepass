import Foundation
import Vision
import UIKit

final class OCRService {
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw AppError.ocrFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: AppError.networkFailure(error.localizedDescription))
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if text.isEmpty {
                    continuation.resume(throwing: AppError.ocrFailed)
                } else {
                    continuation.resume(returning: text)
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let requestHandler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: AppError.ocrFailed)
            }
        }
    }
}
