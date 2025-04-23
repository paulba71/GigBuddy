import Foundation
import CoreLocation
import os

struct TicketmasterEvent: Codable, Identifiable {
    let id: String
    let name: String
    let url: String
    let images: [EventImage]
    let dates: EventDates
    let embedded: Embedded?
    let classifications: [Classification]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, url, images, dates, classifications
        case embedded = "_embedded"
    }
    
    struct EventImage: Codable {
        let url: String
        let width: Int
        let height: Int
    }
    
    struct EventDates: Codable {
        let start: StartDate
        
        struct StartDate: Codable {
            let localDate: String
            let localTime: String?
            let dateTime: String?
        }
    }
    
    struct Embedded: Codable {
        let venues: [Venue]?
        
        struct Venue: Codable {
            let name: String
            let city: City
            let address: Address
            let location: Location?
            
            struct City: Codable {
                let name: String
            }
            
            struct Address: Codable {
                let line1: String
            }
            
            struct Location: Codable {
                let latitude: String?
                let longitude: String?
            }
        }
    }
    
    struct Classification: Codable {
        let segment: Segment?
        
        struct Segment: Codable {
            let name: String
        }
    }
    
    var isMusicEvent: Bool {
        classifications?.first?.segment?.name.lowercased() == "music"
    }
}

class TicketmasterService {
    private let apiKey: String
    private let baseURL = "https://app.ticketmaster.com/discovery/v2"
    
    init(apiKey: String) {
        self.apiKey = apiKey
        os_log("TicketmasterService initialized", log: .default, type: .debug)
        print("TicketmasterService initialized - print")
        NSLog("TicketmasterService initialized - NSLog")
    }
    
    enum ServiceError: Error, LocalizedError {
        case noEvents
        case invalidResponse
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noEvents:
                return "No events found"
            case .invalidResponse:
                return "Invalid response from server"
            case .apiError(let message):
                return message
            }
        }
    }
    
    func discoverUpcomingEvents(latitude: Double?, longitude: Double?, in region: TicketmasterRegion) async throws -> [TicketmasterEvent] {
        var queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "startDateTime", value: ISO8601DateFormatter().string(from: Date())),
            URLQueryItem(name: "countryCode", value: region.countryCode),
            URLQueryItem(name: "sort", value: "date,asc"),
            URLQueryItem(name: "size", value: "50")  // Get more results per page
        ]
        
        if let lat = latitude, let lon = longitude {
            queryItems.append(contentsOf: [
                URLQueryItem(name: "geoPoint", value: "\(lat),\(lon)"),
                URLQueryItem(name: "radius", value: "50"),
                URLQueryItem(name: "unit", value: "miles")
            ])
        }
        
        return try await fetchEvents(endpoint: "/events", queryItems: queryItems)
    }
    
    func searchEvents(keyword: String, in region: TicketmasterRegion) async throws -> [TicketmasterEvent] {
        let queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "countryCode", value: region.countryCode),
            URLQueryItem(name: "size", value: "50")  // Get more results per page
        ]
        
        return try await fetchEvents(endpoint: "/events", queryItems: queryItems)
    }
    
    private func fetchEvents(endpoint: String, queryItems: [URLQueryItem]) async throws -> [TicketmasterEvent] {
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw ServiceError.invalidResponse
        }
        
        print("Fetching events from URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw ServiceError.apiError("Invalid API key")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        print("Response data: \(responseString.prefix(1000))")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            return searchResponse._embedded?.events ?? []
        } catch {
            print("Decoding error: \(error)")
            throw ServiceError.invalidResponse
        }
    }
    
    private struct SearchResponse: Codable {
        let _embedded: EmbeddedResponse?
        let page: Page?
        
        enum CodingKeys: String, CodingKey {
            case _embedded = "_embedded"
            case page
        }
        
        struct EmbeddedResponse: Codable {
            let events: [TicketmasterEvent]
        }
        
        struct Page: Codable {
            let totalElements: Int
            let totalPages: Int
            let number: Int
            let size: Int
        }
    }
}

enum ServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidApiKey
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidApiKey:
            return "Invalid API key"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
} 
