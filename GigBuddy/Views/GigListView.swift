import SwiftUI

struct GigListView: View {
    @ObservedObject var viewModel: GigViewModel
    @State private var searchText = ""
    @State private var showingPastGigs = false
    
    var filteredUpcomingGigs: [Gig] {
        if searchText.isEmpty {
            return viewModel.upcomingGigs
        } else {
            return viewModel.upcomingGigs.filter { gig in
                gig.artist.localizedCaseInsensitiveContains(searchText) ||
                gig.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var filteredPastGigs: [Gig] {
        if searchText.isEmpty {
            return viewModel.pastGigs
        } else {
            return viewModel.pastGigs.filter { gig in
                gig.artist.localizedCaseInsensitiveContains(searchText) ||
                gig.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            // Upcoming Gigs Section
            if !filteredUpcomingGigs.isEmpty {
                Section(header: Text("Upcoming Gigs")) {
                    ForEach(filteredUpcomingGigs) { gig in
                        NavigationLink(destination: GigDetailView(viewModel: viewModel, gig: gig)) {
                            GigRowView(gig: gig)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteGig(filteredUpcomingGigs[index])
                        }
                    }
                }
            }
            
            // Past Gigs Section
            if !filteredPastGigs.isEmpty {
                Section(header: Text("Past Gigs")) {
                    DisclosureGroup(
                        isExpanded: $showingPastGigs,
                        content: {
                            ForEach(filteredPastGigs) { gig in
                                NavigationLink(destination: GigDetailView(viewModel: viewModel, gig: gig)) {
                                    GigRowView(gig: gig)
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    viewModel.deleteGig(filteredPastGigs[index])
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text("Show Past Gigs")
                                Spacer()
                                Text("\(viewModel.pastGigs.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
                }
            }
            
            if filteredUpcomingGigs.isEmpty && filteredPastGigs.isEmpty {
                Section {
                    Text(searchText.isEmpty ? "No gigs found" : "No matches found")
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search gigs")
    }
}

struct GigRowView: View {
    let gig: Gig
    
    var body: some View {
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
                HStack {
                    Text(gig.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "ticket.fill")
                            .font(.caption)
                        Text("\(gig.ticketCount)")
                            .font(.caption)
                    }
                    .foregroundColor(gig.ticketCount > 0 ? .green : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 