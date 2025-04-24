import SwiftUI

struct AboutView: View {
    // Get the app version from the bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // Get the build number from the bundle
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "music.mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("GigBuddy")
                        .font(.title)
                        .bold()
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Written by Paul Barnes")
                        .font(.headline)
                    Text("© \(Calendar.current.component(.year, from: Date()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Acknowledgments")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Event Data")
                        .font(.headline)
                    Text("Powered by the Ticketmaster Discovery API")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Setlist Information")
                        .font(.headline)
                        .padding(.top, 8)
                    Text("Provided by setlist.fm")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Music Integration")
                        .font(.headline)
                        .padding(.top, 8)
                    Text("Playlist generation powered by Spotify")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("About")
    }
} 