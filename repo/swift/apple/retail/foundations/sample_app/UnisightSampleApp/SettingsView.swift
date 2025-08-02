import SwiftUI

struct SettingsView: View {
    @State private var telemetryEnabled = true
    @State private var pushNotifications = false
    @State private var biometricAuth = false
    @State private var darkMode = false
    @State private var showingTelemetryInfo = false
    
    var body: some View {
        NavigationView {
            List {
                // Telemetry Section
                Section("Telemetry & Analytics") {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Enable Telemetry")
                                .font(.headline)
                            Text("Help improve the app with usage analytics")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $telemetryEnabled)
                            .onChange(of: telemetryEnabled) { oldValue, newValue in
                                TelemetryService.shared.logUserInteraction(
                                    .tap,
                                    viewName: "Settings",
                                    elementId: "telemetry_toggle"
                                )
                            }
                    }
                    
                    Button("View Telemetry Info") {
                        showingTelemetryInfo = true
                        TelemetryService.shared.logUserInteraction(
                            .tap,
                            viewName: "Settings",
                            elementId: "telemetry_info_button"
                        )
                    }
                    .foregroundColor(.blue)
                }
                
                // App Preferences
                Section("App Preferences") {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Push Notifications",
                        subtitle: "Receive updates and offers",
                        toggle: $pushNotifications
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            pushNotifications ? "notifications_enabled" : "notifications_disabled",
                            viewName: "Settings",
                            elementId: "notifications_toggle"
                        )
                    }
                    
                    SettingsRow(
                        icon: "faceid",
                        iconColor: .green,
                        title: "Biometric Authentication",
                        subtitle: "Use Face ID or Touch ID",
                        toggle: $biometricAuth
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            biometricAuth ? "biometric_enabled" : "biometric_disabled",
                            viewName: "Settings",
                            elementId: "biometric_toggle"
                        )
                    }
                    
                    SettingsRow(
                        icon: "moon.fill",
                        iconColor: .purple,
                        title: "Dark Mode",
                        subtitle: "Use dark appearance",
                        toggle: $darkMode
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            darkMode ? "dark_mode_enabled" : "dark_mode_disabled",
                            viewName: "Settings",
                            elementId: "dark_mode_toggle"
                        )
                    }
                }
                
                // Account Section
                Section("Account") {
                    SettingsButton(
                        icon: "person.circle.fill",
                        iconColor: .blue,
                        title: "Profile",
                        subtitle: "Manage your account"
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            "profile_tapped",
                            viewName: "Settings",
                            elementId: "profile_button"
                        )
                    }
                    
                    SettingsButton(
                        icon: "creditcard.fill",
                        iconColor: .green,
                        title: "Payment Methods",
                        subtitle: "Manage cards and payment options"
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            "payment_methods_tapped",
                            viewName: "Settings",
                            elementId: "payment_button"
                        )
                    }
                    
                    SettingsButton(
                        icon: "location.fill",
                        iconColor: .red,
                        title: "Addresses",
                        subtitle: "Manage shipping addresses"
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            "addresses_tapped",
                            viewName: "Settings",
                            elementId: "addresses_button"
                        )
                    }
                }
                
                // Support Section
                Section("Support") {
                    SettingsButton(
                        icon: "questionmark.circle.fill",
                        iconColor: .orange,
                        title: "Help & FAQ",
                        subtitle: "Get help and find answers"
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            "help_tapped",
                            viewName: "Settings",
                            elementId: "help_button"
                        )
                    }
                    
                    SettingsButton(
                        icon: "envelope.fill",
                        iconColor: .blue,
                        title: "Contact Support",
                        subtitle: "Get in touch with our team"
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            "contact_support_tapped",
                            viewName: "Settings",
                            elementId: "contact_button"
                        )
                    }
                    
                    SettingsButton(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Rate the App",
                        subtitle: "Share your feedback"
                    ) {
                        TelemetryService.shared.logUserInteraction(
                            "rate_app_tapped",
                            viewName: "Settings",
                            elementId: "rate_button"
                        )
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("100")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                TelemetryService.shared.logEvent(
                    name: "settings_viewed",
                    category: .navigation
                )
            }
        }
        .sheet(isPresented: $showingTelemetryInfo) {
            TelemetryInfoView()
        }
    }
}

// MARK: - Supporting Views

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var toggle: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $toggle)
                .onChange(of: toggle) { _, _ in
                    onToggle()
                }
        }
    }
}

struct SettingsButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}

struct TelemetryInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("We collect anonymous usage data to improve your experience:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoItem(
                            icon: "hand.tap.fill",
                            title: "User Interactions",
                            description: "Taps, swipes, and navigation patterns"
                        )
                        
                        InfoItem(
                            icon: "network",
                            title: "Performance Data",
                            description: "App load times and network requests"
                        )
                        
                        InfoItem(
                            icon: "exclamationmark.triangle.fill",
                            title: "Error Reports",
                            description: "Crashes and technical issues"
                        )
                        
                        InfoItem(
                            icon: "chart.bar.fill",
                            title: "Usage Analytics",
                            description: "Feature usage and screen views"
                        )
                    }
                    
                    Text("Privacy Protection")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• No personal information is collected\n• All data is anonymized\n• You can opt out anytime\n• Data is encrypted in transit")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Telemetry Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}