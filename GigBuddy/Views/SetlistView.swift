import SwiftUI

struct SetlistView: View {
    let artistName: String
    @State private var setlists: [Setlist] = []
    @State private var isLoading = true
    @State private var error: String?
    
    private let setlistService = SetlistFMService()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading setlists...")
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
            } else if setlists.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No setlists found for \(artistName)")
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(setlists) { setlist in
                        Section(header: SetlistHeaderView(setlist: setlist)) {
                            ForEach(setlist.sets.set.indices, id: \.self) { setIndex in
                                let currentSet = setlist.sets.set[setIndex]
                                SetlistSetView(setlistSet: currentSet)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Past Setlists")
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

struct SetlistHeaderView: View {
    let setlist: Setlist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(setlist.formattedDate)
                .font(.headline)
            Text("\(setlist.venue.name), \(setlist.venue.city.name)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SetlistSetView: View {
    let setlistSet: SetlistSet
    
    var setName: String {
        if let encore = setlistSet.encore {
            return "Encore \(encore)"
        }
        return setlistSet.name ?? "Main Set"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(setName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            
            ForEach(setlistSet.song) { song in
                HStack {
                    Text(song.name)
                    if let info = song.info {
                        Text("(\(info))")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    if song.cover != nil {
                        Image(systemName: "music.note")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
} 