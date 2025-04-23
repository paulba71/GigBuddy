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
    
    init() {
        loadGigs()
    }
    
    func addGig(_ gig: Gig) {
        gigs.append(gig)
        saveGigs()
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
            gigs = decoded.sorted { $0.date < $1.date }
        }
    }
} 