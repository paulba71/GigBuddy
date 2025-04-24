import SwiftUI

struct Version {
    static let current = Version(major: 1, minor: 0, patch: 0, releaseType: .rc)
    
    let major: Int
    let minor: Int
    let patch: Int
    let releaseType: ReleaseType
    
    enum ReleaseType: String {
        case alpha = "Alpha"
        case beta = "Beta"
        case rc = "RC"
        case release = ""
        
        var description: String {
            self == .release ? "" : " \(rawValue)"
        }
    }
    
    var description: String {
        "\(major).\(minor).\(patch)\(releaseType.description)"
    }
}

struct AboutView: View {
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
                    
                    Text("Version \(Version.current.description) (\(buildNumber))")
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