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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event data provided by:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link(destination: URL(string: "https://developer.ticketmaster.com")!) {
                        HStack {
                            Text("Ticketmaster")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Link(destination: URL(string: "https://www.setlist.fm")!) {
                        HStack {
                            Text("setlist.fm")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    
                    Text("This app uses the setlist.fm API but is not endorsed or certified by setlist.fm. Setlist data © setlist.fm and its contributors.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("About")
    }
} 