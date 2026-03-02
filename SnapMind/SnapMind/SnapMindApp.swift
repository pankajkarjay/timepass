import SwiftUI

@main
struct SnapMindApp: App {
    @StateObject private var viewModel = HomeViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(viewModel)
        }
    }
}
