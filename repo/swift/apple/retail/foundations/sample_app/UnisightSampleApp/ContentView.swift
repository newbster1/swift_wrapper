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
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Log tab changes
            let tabNames = ["Products", "Settings"]
            TelemetryService.shared.logNavigation(
                from: tabNames[safe: oldValue],
                to: tabNames[safe: newValue] ?? "Unknown"
            )
        }
        .onAppear {
            TelemetryService.shared.logEvent(
                name: "main_view_appeared",
                category: .navigation
            )
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