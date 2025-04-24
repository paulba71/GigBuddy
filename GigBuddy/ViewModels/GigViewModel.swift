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
    
    enum ImportError: Error, LocalizedError {
        case invalidData
        case fileError
        
        var errorDescription: String? {
            switch self {
            case .invalidData:
                return "The selected file contains invalid data."
            case .fileError:
                return "Unable to read the selected file."
            }
        }
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
    
    func deleteAllGigs() {
        gigs.removeAll()
        saveGigs()
    }
    
    func deleteFutureGigs() {
        let today = Calendar.current.startOfDay(for: Date())
        gigs.removeAll { gig in
            let gigDate = Calendar.current.startOfDay(for: gig.date)
            return gigDate >= today
        }
        saveGigs()
    }
    
    // Export gigs to a JSON file
    func exportGigs() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(gigs) else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "gigbuddy-backup-\(dateFormatter.string(from: Date())).json"
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error exporting gigs: \(error)")
            return nil
        }
    }
    
    // Import gigs from a JSON file
    func importGigs(from url: URL) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: url)
            let importedGigs = try decoder.decode([Gig].self, from: data)
            
            // Merge imported gigs with existing ones, avoiding duplicates
            for gig in importedGigs {
                if !gigs.contains(where: { $0.id == gig.id }) {
                    gigs.append(gig)
                }
            }
            
            saveGigs()
        } catch {
            throw ImportError.invalidData
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