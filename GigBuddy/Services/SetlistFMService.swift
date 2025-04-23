import Foundation

struct SetlistFMService {
    private let apiKey = "BS5vHTZ5bpU4KDVx5ZLJgj1KJtDJ24LgTiO2"
    private let baseURL = "https://api.setlist.fm/rest/1.0"
    
    enum ServiceError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from server"
            case .apiError(let message):
                return message
            }
        }
    }
    
    func searchSetlists(forArtist artistName: String) async throws -> [Setlist] {
        var components = URLComponents(string: "\(baseURL)/search/setlists")!
        components.queryItems = [
            URLQueryItem(name: "artistName", value: artistName),
            URLQueryItem(name: "p", value: "1")  // Page number
        ]
        
        guard let url = components.url else {
            throw ServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let searchResponse = try decoder.decode(SetlistSearchResponse.self, from: data)
                return searchResponse.setlist
            case 401:
                throw ServiceError.apiError("Invalid API key")
            case 404:
                throw ServiceError.apiError("No setlists found for this artist")
            default:
                throw ServiceError.apiError("Server error (Status \(httpResponse.statusCode))")
            }
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.networkError(error)
        }
    }
}

// MARK: - Response Models
struct SetlistSearchResponse: Codable {
    let type: String
    let itemsPerPage: Int
    let page: Int
    let total: Int
    let setlist: [Setlist]
}

struct Setlist: Codable, Identifiable {
    let id: String
    let eventDate: String
    let artist: Artist
    let venue: Venue
    let sets: Sets
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        if let date = formatter.date(from: eventDate) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return eventDate
    }
}

struct Artist: Codable {
    let mbid: String
    let name: String
    let sortName: String
    let disambiguation: String?
}

struct Venue: Codable {
    let id: String
    let name: String
    let city: City
}

struct City: Codable {
    let id: String
    let name: String
    let state: String?
    let stateCode: String?
    let coords: Coords?
    let country: Country
}

struct Coords: Codable {
    let lat: Double
    let long: Double
}

struct Country: Codable {
    let code: String
    let name: String
}

struct Sets: Codable {
    let set: [SetlistSet]
}

struct SetlistSet: Codable {
    let name: String?
    let encore: Int?
    let song: [Song]
}

struct Song: Codable, Identifiable {
    var id: String { name }  // Using name as id since the API doesn't provide one
    let name: String
    let info: String?
    let cover: Cover?
}

struct Cover: Codable {
    let mbid: String
    let name: String
    let sortName: String
} 