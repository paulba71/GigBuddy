import SwiftUI

struct PastGigsView: View {
    let artistName: String
    @State private var setlists: [Setlist] = []
    @State private var isLoading = true
    @State private var error: String?
    
    private let setlistService = SetlistFMService()
    
    var filteredSetlists: [Setlist] {
        setlists.filter { setlist in
            // Only include setlists that have at least one song
            setlist.sets.set.reduce(0) { count, set in
                count + set.song.count
            } > 0
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Finding past gigs for \(artistName)...")
                        .foregroundColor(.secondary)
                }
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    Text(error)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await loadSetlists()
                        }
                    }
                }
                .padding()
            } else if filteredSetlists.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.mic")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No past gigs found for \(artistName)")
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredSetlists) { setlist in
                            NavigationLink(destination: SetlistDetailView(setlist: setlist)) {
                                PastGigCard(setlist: setlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Past Gigs")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadSetlists()
        }
    }
    
    private func loadSetlists() async {
        isLoading = true
        error = nil
        
        do {
            setlists = try await setlistService.searchSetlists(forArtist: artistName)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

struct PastGigCard: View {
    let setlist: Setlist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date
            Text(formattedDate)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Venue
            Text(setlist.venue.name)
                .font(.title3)
                .foregroundColor(.primary)
            
            // Location
            Text(formattedLocation)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Song count with icon
            HStack {
                Text("\(songCount) songs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "music.note.list")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        if let date = formatter.date(from: setlist.eventDate) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return setlist.eventDate
    }
    
    private var formattedLocation: String {
        var components: [String] = []
        components.append(setlist.venue.city.name)
        
        if let state = setlist.venue.city.state {
            components.append(state)
        }
        
        components.append(setlist.venue.city.country.name)
        
        return components.joined(separator: " , ")
    }
    
    private var songCount: Int {
        setlist.sets.set.reduce(0) { count, set in
            count + set.song.count
        }
    }
} 