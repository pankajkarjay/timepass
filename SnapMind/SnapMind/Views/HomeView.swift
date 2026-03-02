import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if viewModel.canShowUpgradePrompt {
                    proBanner
                }

                if viewModel.filteredCards.isEmpty {
                    emptyState
                } else {
                    List(viewModel.filteredCards) { card in
                        NavigationLink(value: card) {
                            KnowledgeCardRow(card: card)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("SnapMind")
            .navigationDestination(for: KnowledgeCard.self) { card in
                DetailView(card: card)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.scanScreenshots() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Label("Scan", systemImage: "sparkles")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay(alignment: .bottom) {
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                }
            }
            .task {
                viewModel.loadStoredCards()
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search knowledge", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding()
    }

    private var proBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free plan: 5 screenshots")
                    .font(.subheadline.weight(.semibold))
                Text("Unlock Pro for unlimited processing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Unlock Pro") {}
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.stack")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No knowledge cards yet")
                .font(.headline)
            Text("Tap Scan to process your latest screenshots.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
