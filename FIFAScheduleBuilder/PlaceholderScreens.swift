import SwiftUI

// MARK: - Settings View

struct AppSettingsView: View {
    @State private var useMockMode = GoogleMapsConfig.useMockMode
    @ObservedObject private var layoutPreference = LayoutPreferenceService.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Layout Style")) {
                    Picker("Layout", selection: $layoutPreference.layoutStyle) {
                        ForEach(LayoutPreferenceService.LayoutStyle.allCases, id: \.self) { style in
                            HStack {
                                Image(systemName: style.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.displayName)
                                    Text(style.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.inline)

                    Text("Choose how you want to navigate the app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("App Mode")) {
                    Toggle(isOn: $useMockMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Demo Mode")
                                .font(.headline)
                            Text(useMockMode ? "Using mock data (no API calls)" : "Using real Google Maps APIs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: useMockMode) { _, newValue in
                        GoogleMapsConfig.useMockMode = newValue
                    }

                    if !useMockMode {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Requires Google Maps API key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2026.1")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Support")) {
                    Link("Help Center", destination: URL(string: "https://example.com/help")!)
                    Link("Contact Us", destination: URL(string: "https://example.com/contact")!)
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                }

                Section(header: Text("Features")) {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Google Maps Integration")
                                .font(.headline)
                            Text("Real-time traffic & routing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Crowd Intelligence")
                                .font(.headline)
                            Text("Avoid peak times & congestion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Smart Notifications")
                                .font(.headline)
                            Text("Never miss departure time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Help & Info")
        }
    }
}
