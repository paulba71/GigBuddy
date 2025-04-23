import SwiftUI

struct SetlistDetailView: View {
    let setlist: Setlist
    
    var body: some View {
        List {
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
    }
    
    private func getSetName(for set: SetlistSet) -> String {
        if let encore = set.encore {
            return "Encore \(encore)"
        }
        return set.name ?? "Main Set"
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