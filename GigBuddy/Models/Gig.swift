import Foundation

struct Gig: Identifiable, Codable {
    let id: UUID
    var date: Date
    var artist: String
    var location: String
    var rating: Int
    var ticketmasterId: String?
    var ticketmasterUrl: String?
    var imageUrl: String?
    
    init(id: UUID = UUID(), 
         date: Date, 
         artist: String, 
         location: String, 
         rating: Int,
         ticketmasterId: String? = nil,
         ticketmasterUrl: String? = nil,
         imageUrl: String? = nil) {
        self.id = id
        self.date = date
        self.artist = artist
        self.location = location
        self.rating = rating
        self.ticketmasterId = ticketmasterId
        self.ticketmasterUrl = ticketmasterUrl
        self.imageUrl = imageUrl
    }
    
    init(from ticketmasterEvent: TicketmasterEvent) {
        self.id = UUID()
        self.artist = ticketmasterEvent.name
        self.ticketmasterId = ticketmasterEvent.id
        self.ticketmasterUrl = ticketmasterEvent.url
        
        // Set the date
        if let dateTime = ticketmasterEvent.dates.start.dateTime {
            self.date = ISO8601DateFormatter().date(from: dateTime) ?? Date()
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.date = dateFormatter.date(from: ticketmasterEvent.dates.start.localDate) ?? Date()
        }
        
        // Set the location
        if let venue = ticketmasterEvent.embedded?.venues?.first {
            self.location = "\(venue.name), \(venue.city.name)"
        } else {
            self.location = "Unknown Venue"
        }
        
        // Set the image URL
        self.imageUrl = ticketmasterEvent.images.first?.url
        
        // Default rating
        self.rating = 3
    }
} 