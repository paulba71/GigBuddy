import Foundation

struct TicketmasterRegion: Identifiable, Hashable {
    let id: String
    let name: String
    let countryCode: String
    let marketId: String?  // Add market ID for specific regions
    
    static let allRegions: [TicketmasterRegion] = [
        TicketmasterRegion(id: "US", name: "United States", countryCode: "US", marketId: nil),
        TicketmasterRegion(id: "GB", name: "United Kingdom", countryCode: "GB", marketId: nil),
        TicketmasterRegion(id: "CA", name: "Canada", countryCode: "CA", marketId: nil),
        TicketmasterRegion(id: "AU", name: "Australia", countryCode: "AU", marketId: nil),
        TicketmasterRegion(id: "NZ", name: "New Zealand", countryCode: "NZ", marketId: nil),
        TicketmasterRegion(id: "IE", name: "Ireland", countryCode: "IE", marketId: nil),
        TicketmasterRegion(id: "DE", name: "Germany", countryCode: "DE", marketId: nil),
        TicketmasterRegion(id: "FR", name: "France", countryCode: "FR", marketId: nil),
        TicketmasterRegion(id: "ES", name: "Spain", countryCode: "ES", marketId: nil),
        TicketmasterRegion(id: "IT", name: "Italy", countryCode: "IT", marketId: nil),
        TicketmasterRegion(id: "NL", name: "Netherlands", countryCode: "NL", marketId: nil),
        TicketmasterRegion(id: "BE", name: "Belgium", countryCode: "BE", marketId: nil),
        TicketmasterRegion(id: "SE", name: "Sweden", countryCode: "SE", marketId: nil),
        TicketmasterRegion(id: "DK", name: "Denmark", countryCode: "DK", marketId: nil),
        TicketmasterRegion(id: "NO", name: "Norway", countryCode: "NO", marketId: nil),
        TicketmasterRegion(id: "FI", name: "Finland", countryCode: "FI", marketId: nil)
    ]
    
    static func region(for countryCode: String) -> TicketmasterRegion? {
        allRegions.first { $0.countryCode == countryCode }
    }
} 
