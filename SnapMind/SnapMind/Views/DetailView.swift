import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    let card: KnowledgeCard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(card.classification.title)
                    .font(.title2.weight(.semibold))

                Text(card.classification.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)

                infoRow(label: "Category", value: card.classification.type)
                infoRow(label: "Amount", value: card.classification.importantData.amount)
                infoRow(label: "Date", value: card.classification.importantData.date)
                infoRow(label: "Company", value: card.classification.importantData.company)
                infoRow(label: "Location", value: card.classification.importantData.location)
                infoRow(label: "Tags", value: card.classification.tags.joined(separator: ", "))

                Divider().padding(.vertical, 4)

                Text("Extracted Text")
                    .font(.headline)
                Text(card.extractedText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Convert to Note") {
                    viewModel.convertToNote(card: card)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)

                if let note = viewModel.cards.first(where: { $0.id == card.id })?.convertedNote {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved Local Note")
                            .font(.headline)
                        Text(note.content)
                            .font(.footnote)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding()
        }
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(width: 90, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
