import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ProductListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Products")
                }
                .tag(0)
                .trackScreen("ProductList")

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
                .trackScreen("Settings")
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            let tabNames = ["Products", "Settings"]
            TelemetryService.shared.logNavigation(
                from: tabNames[safe: oldValue],
                to: tabNames[safe: newValue] ?? "Unknown",
                method: .tab
            )
        }
        .onAppear {
            TelemetryService.shared.logScreenAppeared("MainTabView")
        }
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
}