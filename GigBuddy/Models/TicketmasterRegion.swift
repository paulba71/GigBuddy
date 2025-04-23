import Foundation

struct TicketmasterRegion: Identifiable, Hashable {
    let id: String
    let name: String
    let countryCode: String
    
    static let allRegions: [TicketmasterRegion] = [
        TicketmasterRegion(id: "US", name: "United States", countryCode: "US"),
        TicketmasterRegion(id: "GB", name: "United Kingdom", countryCode: "GB"),
        TicketmasterRegion(id: "CA", name: "Canada", countryCode: "CA"),
        TicketmasterRegion(id: "AU", name: "Australia", countryCode: "AU"),
        TicketmasterRegion(id: "NZ", name: "New Zealand", countryCode: "NZ"),
        TicketmasterRegion(id: "IE", name: "Ireland", countryCode: "IE"),
        TicketmasterRegion(id: "DE", name: "Germany", countryCode: "DE"),
        TicketmasterRegion(id: "FR", name: "France", countryCode: "FR"),
        TicketmasterRegion(id: "ES", name: "Spain", countryCode: "ES"),
        TicketmasterRegion(id: "IT", name: "Italy", countryCode: "IT"),
        TicketmasterRegion(id: "NL", name: "Netherlands", countryCode: "NL"),
        TicketmasterRegion(id: "BE", name: "Belgium", countryCode: "BE"),
        TicketmasterRegion(id: "SE", name: "Sweden", countryCode: "SE"),
        TicketmasterRegion(id: "DK", name: "Denmark", countryCode: "DK"),
        TicketmasterRegion(id: "NO", name: "Norway", countryCode: "NO"),
        TicketmasterRegion(id: "FI", name: "Finland", countryCode: "FI")
    ]
    
    static func region(for countryCode: String) -> TicketmasterRegion? {
        allRegions.first { $0.countryCode == countryCode }
    }
} 