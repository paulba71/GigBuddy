import Foundation
import CoreLocation
import os

struct TicketmasterEvent: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let url: String?
    let images: [EventImage]
    let dates: EventDates
    let embedded: Embedded?
    let classifications: [Classification]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, url, images, dates, classifications
        case embedded = "_embedded"
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TicketmasterEvent, rhs: TicketmasterEvent) -> Bool {
        lhs.id == rhs.id
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
            let name: String?
            let city: City?
            let address: Address?
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
    
    func discoverUpcomingEvents(latitude: Double?, longitude: Double?, in regions: [TicketmasterRegion]) async throws -> [TicketmasterEvent] {
        var allEvents: [TicketmasterEvent] = []
        
        for region in regions {
            var queryItems = [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "startDateTime", value: ISO8601DateFormatter().string(from: Date())),
                URLQueryItem(name: "countryCode", value: region.countryCode),
                URLQueryItem(name: "sort", value: "date,asc"),
                URLQueryItem(name: "size", value: "50")
            ]
            
            if let lat = latitude, let lon = longitude {
                queryItems.append(contentsOf: [
                    URLQueryItem(name: "geoPoint", value: "\(lat),\(lon)"),
                    URLQueryItem(name: "radius", value: "300"),
                    URLQueryItem(name: "unit", value: "miles")
                ])
            }
            
            print("Discovering events for region: \(region.name) (countryCode: \(region.countryCode))")
            let events = try await fetchEvents(endpoint: "/events", queryItems: queryItems)
            allEvents.append(contentsOf: events)
        }
        
        // Remove duplicates and sort by date
        return Array(Set(allEvents)).sorted { $0.dates.start.dateTime ?? $0.dates.start.localDate < $1.dates.start.dateTime ?? $1.dates.start.localDate }
    }
    
    func searchEvents(keyword: String, in regions: [TicketmasterRegion]) async throws -> [TicketmasterEvent] {
        var allEvents: [TicketmasterEvent] = []
        
        for region in regions {
            var queryItems = [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "countryCode", value: region.countryCode),
                URLQueryItem(name: "size", value: "50")
            ]
            
            print("Searching events for region: \(region.name) (countryCode: \(region.countryCode))")
            let events = try await fetchEvents(endpoint: "/events", queryItems: queryItems)
            allEvents.append(contentsOf: events)
        }
        
        // Remove duplicates and sort by date
        return Array(Set(allEvents)).sorted { $0.dates.start.dateTime ?? $0.dates.start.localDate < $1.dates.start.dateTime ?? $1.dates.start.localDate }
    }
    
    private func fetchEvents(endpoint: String, queryItems: [URLQueryItem]) async throws -> [TicketmasterEvent] {
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw ServiceError.invalidResponse
        }
        
        print("Fetching events from URL: \(url)")
        // print("Query parameters:")
        // queryItems.forEach { item in
        //     print("- \(item.name): \(item.value ?? \"nil\")")
        // }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        
        // print("Response status code: \(httpResponse.statusCode)")
        // let responseString = String(data: data, encoding: .utf8) ?? ""
        // print("Response data: \(responseString)")
        
        if httpResponse.statusCode == 401 {
            throw ServiceError.apiError("Invalid API key")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorMessage = try? JSONDecoder().decode(TicketmasterAPIError.self, from: data) {
                print("API error message: \(errorMessage.error)")
                throw ServiceError.apiError(errorMessage.error)
            }
            throw ServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            let events = searchResponse._embedded?.events ?? []
            print("Successfully decoded \(events.count) events")
            return events
        } catch {
            let snippet = String(data: data, encoding: .utf8)?.prefix(500) ?? "N/A"
            print("Decoding error: \(error)")
            print("Response snippet: \(snippet)")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Top-level keys: \(json.keys)")
            }
            throw ServiceError.apiError("Decoding error: \(error.localizedDescription)")
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
    
    private struct TicketmasterAPIError: Codable {
        let error: String
        let status: Int?
        let message: String?
        // Some Ticketmaster errors use 'errors' array
        let errors: [String]?
        
        // Custom decoding to handle different error formats
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            error = (try? container.decode(String.self, forKey: .error)) ?? (try? container.decode(String.self, forKey: .message)) ?? "Unknown error"
            status = try? container.decode(Int.self, forKey: .status)
            message = try? container.decode(String.self, forKey: .message)
            errors = try? container.decode([String].self, forKey: .errors)
        }
        
        enum CodingKeys: String, CodingKey {
            case error, status, message, errors
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
