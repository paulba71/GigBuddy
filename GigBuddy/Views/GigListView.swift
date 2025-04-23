import SwiftUI

struct GigListView: View {
    @ObservedObject var viewModel: GigViewModel
    @State private var searchText = ""
    
    var filteredGigs: [Gig] {
        if searchText.isEmpty {
            return viewModel.gigs
        } else {
            return viewModel.gigs.filter { gig in
                gig.artist.localizedCaseInsensitiveContains(searchText) ||
                gig.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredGigs) { gig in
                NavigationLink(destination: GigDetailView(viewModel: viewModel, gig: gig)) {
                    HStack(spacing: 12) {
                        if let imageUrl = gig.imageUrl,
                           let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        } else {
                            Image(systemName: "music.mic")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(gig.artist)
                                .font(.headline)
                                .lineLimit(1)
                            Text(gig.location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text(gig.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteGig(filteredGigs[index])
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search gigs")
    }
} 