# SnapMind iOS MVP (SwiftUI, iOS 16+)

SnapMind scans the **Screenshots** smart album, runs on-device OCR with Vision, sends only extracted text to OpenAI, then saves structured knowledge cards locally.

## Project Structure

```
SnapMind/
  SnapMind/
    SnapMindApp.swift
    Models/
      KnowledgeCard.swift
      AppError.swift
    Services/
      PhotoScannerService.swift
      OCRService.swift
      AIClassifierService.swift
    Storage/
      KnowledgeStore.swift
    Utils/
      NoteFormatter.swift
    ViewModels/
      HomeViewModel.swift
    Views/
      HomeView.swift
      KnowledgeCardRow.swift
      DetailView.swift
```

## Key Behaviors Implemented

- Photos permission prompt with clear failure handling.
- Scans only the iOS `smartAlbumScreenshots` collection.
- Free tier process limit of 5 screenshots (`Unlock Pro` is placeholder UI only).
- OCR runs on-device via Vision (`VNRecognizeTextRequest`).
- Sends **text only** to OpenAI chat completions endpoint.
- Requires strict JSON schema from AI response.
- Saves cards locally to JSON in Documents directory.
- Searchable SwiftUI home list, detail screen, and `Convert to Note` local formatting.

## Xcode Setup (Step-by-Step)

1. Open **Xcode 15+**.
2. Create a new app:
   - Template: **iOS App**
   - Name: `SnapMind`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 16.0**
3. Replace generated Swift files with files inside `SnapMind/SnapMind/`.
4. In `Info.plist`, add:
   - `Privacy - Photo Library Usage Description` (`NSPhotoLibraryUsageDescription`)
   - Suggested value: `SnapMind scans your Screenshots album to extract text and build local knowledge cards.`
5. In Scheme:
   - **Product > Scheme > Edit Scheme... > Run > Arguments > Environment Variables**
   - Add `OPENAI_API_KEY` with your API key value.
6. Build and run on a physical iPhone (recommended) or simulator with photos access configured.
7. Tap **Scan** on the home screen.

## Notes

- No backend server, no account system, and no cloud image upload.
- If API key is missing or denied Photos access, error banners appear in-app.
- For production hardening, add request debouncing, retries, and richer schema validation.
