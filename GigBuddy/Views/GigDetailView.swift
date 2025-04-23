import SwiftUI

struct GigDetailView: View {
    @ObservedObject var viewModel: GigViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var artist: String
    @State private var location: String
    @State private var date: Date
    @State private var rating: Int
    @State private var imageUrl: String?
    @State private var ticketmasterUrl: String?
    
    private var gig: Gig?
    
    init(viewModel: GigViewModel, gig: Gig? = nil) {
        self.viewModel = viewModel
        self.gig = gig
        
        _artist = State(initialValue: gig?.artist ?? "")
        _location = State(initialValue: gig?.location ?? "")
        _date = State(initialValue: gig?.date ?? Date())
        _rating = State(initialValue: gig?.rating ?? 3)
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
                
                if let ticketmasterUrl = ticketmasterUrl,
                   let url = URL(string: ticketmasterUrl) {
                    Section {
                        Link("Buy Tickets on Ticketmaster", destination: url)
                    }
                }
                
                Section {
                    Button(gig == nil ? "Add Gig" : "Update Gig") {
                        let newGig = Gig(
                            id: gig?.id ?? UUID(),
                            date: date,
                            artist: artist,
                            location: location,
                            rating: rating,
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
                }
            }
            .navigationTitle(gig == nil ? "New Gig" : "Edit Gig")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
} 