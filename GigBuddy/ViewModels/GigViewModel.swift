import Foundation
import SwiftUI

@MainActor
class GigViewModel: ObservableObject {
    @Published var gigs: [Gig] = []
    @Published var selectedView: ViewType = .list
    
    enum ViewType {
        case list
        case calendar
    }
    
    var upcomingGigs: [Gig] {
        let today = Calendar.current.startOfDay(for: Date())
        return gigs.filter { gig in
            let gigDate = Calendar.current.startOfDay(for: gig.date)
            return gigDate >= today
        }.sorted { $0.date < $1.date }
    }
    
    var pastGigs: [Gig] {
        let today = Calendar.current.startOfDay(for: Date())
        return gigs.filter { gig in
            let gigDate = Calendar.current.startOfDay(for: gig.date)
            return gigDate < today
        }.sorted { $0.date > $1.date } // Sort past gigs in reverse chronological order
    }
    
    init() {
        loadGigs()
    }
    
    func addGig(_ gig: Gig) {
        // Check if the gig is already in the list
        let isDuplicate = gigs.contains { existingGig in
            // If it's a Ticketmaster event, check the ID
            if let ticketmasterId = gig.ticketmasterId,
               let existingId = existingGig.ticketmasterId {
                return ticketmasterId == existingId
            }
            
            // For manual entries, compare artist, date, and location
            return existingGig.artist == gig.artist &&
                   existingGig.location == gig.location &&
                   Calendar.current.isDate(existingGig.date, inSameDayAs: gig.date)
        }
        
        // Only add if it's not a duplicate
        if !isDuplicate {
            gigs.append(gig)
            saveGigs()
        }
    }
    
    func deleteGig(_ gig: Gig) {
        gigs.removeAll { $0.id == gig.id }
        saveGigs()
    }
    
    func updateGig(_ gig: Gig) {
        if let index = gigs.firstIndex(where: { $0.id == gig.id }) {
            gigs[index] = gig
            saveGigs()
        }
    }
    
    private func saveGigs() {
        if let encoded = try? JSONEncoder().encode(gigs) {
            UserDefaults.standard.set(encoded, forKey: "savedGigs")
        }
    }
    
    private func loadGigs() {
        if let data = UserDefaults.standard.data(forKey: "savedGigs"),
           let decoded = try? JSONDecoder().decode([Gig].self, from: data) {
            gigs = decoded
        }
    }
} 