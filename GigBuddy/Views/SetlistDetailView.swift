import SwiftUI

struct SetlistDetailView: View {
    let setlist: Setlist
    @State private var isCreatingSpotifyPlaylist = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingCreatingPlaylistToast = false
    @State private var showingPlaylistCreatedToast = false
    
    private let spotifyService = SpotifyService(
        clientId: SpotifyConfig.clientId,
        clientSecret: SpotifyConfig.clientSecret
    )
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // Spotify Button
                    Button(action: {
                        createSpotifyPlaylist()
                    }) {
                        HStack {
                            if isCreatingSpotifyPlaylist {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "music.note.list")
                                    .font(.title3)
                            }
                            Text("Create Spotify Playlist")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.11, green: 0.73, blue: 0.33))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    .disabled(isCreatingSpotifyPlaylist)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(setlist.venue.name)
                        .font(.headline)
                    
                    HStack {
                        Text(setlist.venue.city.name)
                        if let state = setlist.venue.city.state {
                            Text(", \(state)")
                        }
                        Text(", \(setlist.venue.city.country.name)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Text(setlist.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            ForEach(setlist.sets.set.indices, id: \.self) { setIndex in
                let currentSet = setlist.sets.set[setIndex]
                Section(header: Text(getSetName(for: currentSet))) {
                    ForEach(currentSet.song) { song in
                        SongRow(song: song)
                    }
                }
            }
        }
        .navigationTitle("Setlist")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .overlay(
            Group {
                if showingCreatingPlaylistToast {
                    Toast(type: .info,
                          title: "Creating Playlist",
                          message: "Finding songs and creating your Spotify playlist...")
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else if showingPlaylistCreatedToast {
                    Toast(type: .success,
                          title: "Success!",
                          message: "Your Spotify playlist has been created.")
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingCreatingPlaylistToast)
            .animation(.easeInOut(duration: 0.3), value: showingPlaylistCreatedToast)
            , alignment: .top
        )
    }
    
    private func getSetName(for set: SetlistSet) -> String {
        if let encore = set.encore {
            return "Encore \(encore)"
        }
        return set.name ?? "Main Set"
    }
    
    private func createSpotifyPlaylist() {
        isCreatingSpotifyPlaylist = true
        withAnimation(.easeInOut(duration: 0.3)) {
            showingCreatingPlaylistToast = true
        }
        
        Task {
            do {
                try await spotifyService.createPlaylist(from: setlist)
                isCreatingSpotifyPlaylist = false
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingCreatingPlaylistToast = false
                    showingPlaylistCreatedToast = true
                }
                
                // Auto-hide the success toast after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingPlaylistCreatedToast = false
                }
            } catch {
                self.error = error
                showingError = true
                isCreatingSpotifyPlaylist = false
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingCreatingPlaylistToast = false
                }
            }
        }
    }
}

struct SongRow: View {
    let song: Song
    
    var body: some View {
        HStack(spacing: 12) {
            if song.cover != nil {
                Text("♪")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.title3)
                
                if let cover = song.cover {
                    Text("Cover of \(cover.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let info = song.info {
                    Text(info)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 