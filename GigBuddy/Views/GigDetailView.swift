import SwiftUI

struct GigDetailView: View {
    @ObservedObject var viewModel: GigViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var artist: String
    @State private var location: String
    @State private var date: Date
    @State private var rating: Int
    @State private var ticketCount: Int
    @State private var imageUrl: String?
    @State private var ticketmasterUrl: String?
    @State private var isLoadingSetlists = false
    @State private var showingSetlists = false
    
    private var gig: Gig?
    
    init(viewModel: GigViewModel, gig: Gig? = nil) {
        self.viewModel = viewModel
        self.gig = gig
        
        _artist = State(initialValue: gig?.artist ?? "")
        _location = State(initialValue: gig?.location ?? "")
        _date = State(initialValue: gig?.date ?? Date())
        _rating = State(initialValue: gig?.rating ?? 3)
        _ticketCount = State(initialValue: gig?.ticketCount ?? 0)
        _imageUrl = State(initialValue: gig?.imageUrl)
        _ticketmasterUrl = State(initialValue: gig?.ticketmasterUrl)
    }
    
    var body: some View {
        NavigationView {
            Form {
                if let imageUrl = imageUrl,
                   let url = URL(string: imageUrl) {
                    Section {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.vertical, 8)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                Section(header: Text("Gig Details")) {
                    TextField("Artist", text: $artist)
                    TextField("Location", text: $location)
                    DatePicker("Date and Time", selection: $date)
                    Stepper(value: $ticketCount, in: 0...99) {
                        HStack {
                            Text("Tickets")
                            Spacer()
                            Text("\(ticketCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Rating")) {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: PastGigsView(artistName: artist)) {
                        HStack(spacing: 12) {
                            Image(systemName: "music.mic")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("View Past Gigs")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                    .disabled(artist.isEmpty)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                if let ticketmasterUrl = ticketmasterUrl,
                   let url = URL(string: ticketmasterUrl) {
                    Section {
                        Link("Buy Tickets on Ticketmaster", destination: url)
                    }
                }
            }
            .navigationTitle(gig == nil ? "New Gig" : "Edit Gig")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(gig == nil ? "Add" : "Update") {
                    let newGig = Gig(
                        id: gig?.id ?? UUID(),
                        date: date,
                        artist: artist,
                        location: location,
                        rating: rating,
                        ticketCount: ticketCount,
                        ticketmasterId: gig?.ticketmasterId,
                        ticketmasterUrl: ticketmasterUrl,
                        imageUrl: imageUrl
                    )
                    
                    if gig != nil {
                        viewModel.updateGig(newGig)
                    } else {
                        viewModel.addGig(newGig)
                    }
                    
                    dismiss()
                }
                .disabled(artist.isEmpty || location.isEmpty)
            )
        }
    }
} 