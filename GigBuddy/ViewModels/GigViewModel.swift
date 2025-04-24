import Foundation
import SwiftUI

@MainActor
class GigViewModel: ObservableObject {
    @Published var gigs: [Gig] = []
    @Published var selectedView: ViewType = .list
    @AppStorage("defaultTicketCount") var defaultTicketCount: Int = 2
    
    enum ViewType {
        case list
        case calendar
    }
    
    enum ImportError: Error, LocalizedError {
        case invalidData
        case fileError
        case emptyFile
        case invalidFormat
        case accessError
        
        var errorDescription: String? {
            switch self {
            case .invalidData:
                return "The selected file contains invalid data."
            case .fileError:
                return "Unable to read the selected file."
            case .emptyFile:
                return "The selected file is empty."
            case .invalidFormat:
                return "The file format is not valid. Please select a GigBuddy backup file."
            case .accessError:
                return "Unable to access the selected file. Please try again."
            }
        }
    }
    
    enum ExportError: LocalizedError {
        case encodingFailed
        case writingFailed
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode gigs data for export"
            case .writingFailed:
                return "Failed to write gigs data to file"
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
            // Create a new gig with the default ticket count if not specified
            var newGig = gig
            if newGig.ticketCount == 0 {
                newGig = Gig(
                    id: gig.id,
                    date: gig.date,
                    artist: gig.artist,
                    location: gig.location,
                    rating: gig.rating,
                    ticketCount: defaultTicketCount,
                    ticketmasterId: gig.ticketmasterId,
                    ticketmasterUrl: gig.ticketmasterUrl,
                    imageUrl: gig.imageUrl
                )
            }
            gigs.append(newGig)
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
    func exportGigs(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(gigs)
            try data.write(to: url, options: .atomic)
        } catch EncodingError.invalidValue(_, _) {
            throw ExportError.encodingFailed
        } catch {
            throw ExportError.writingFailed
        }
    }
    
    // Import gigs from a JSON file
    func importGigs(from url: URL) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Start a coordinated read of the file
            if !url.startAccessingSecurityScopedResource() {
                throw ImportError.accessError
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // Read the data
            let data = try Data(contentsOf: url)
            
            // Validate data is not empty
            guard !data.isEmpty else {
                throw ImportError.emptyFile
            }
            
            // Validate JSON format
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw ImportError.invalidFormat
            }
            
            // Try to decode the data
            let importedGigs = try decoder.decode([Gig].self, from: data)
            
            // Merge imported gigs with existing ones, avoiding duplicates
            for gig in importedGigs {
                if !gigs.contains(where: { $0.id == gig.id }) {
                    gigs.append(gig)
                }
            }
            
            saveGigs()
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw ImportError.invalidData
        } catch let importError as ImportError {
            throw importError
        } catch {
            print("Import error: \(error)")
            throw ImportError.fileError
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