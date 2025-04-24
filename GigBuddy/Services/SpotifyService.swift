import Foundation
import AuthenticationServices

enum SpotifyError: LocalizedError {
    case notAuthorized
    case playlistCreationFailed
    case searchFailed
    case noMatchFound
    case invalidResponse
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Not authorized to access Spotify. Please check your settings."
        case .playlistCreationFailed:
            return "Failed to create playlist in Spotify."
        case .searchFailed:
            return "Failed to search for songs in Spotify."
        case .noMatchFound:
            return "Some songs could not be found in Spotify."
        case .invalidResponse:
            return "Received an invalid response from Spotify."
        case .authenticationFailed:
            return "Failed to authenticate with Spotify."
        }
    }
}

class SpotifyService: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let clientId: String
    private let clientSecret: String
    private var accessToken: String?
    private var tokenExpirationDate: Date?
    private var userAccessToken: String?
    
    init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        super.init()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            // Fallback to first available window if no scene is available
            return UIApplication.shared.windows.first!
        }
        return window
    }
    
    private func authenticateUser() async throws -> String {
        if let token = userAccessToken {
            return token
        }
        
        // Define the OAuth parameters
        let redirectUri = "gigbuddy://spotify-callback"
        let scope = "playlist-modify-public playlist-modify-private"
        let state = UUID().uuidString
        
        // Create the authorization URL
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state)
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: components.url!,
                callbackURLScheme: "gigbuddy"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
                      let returnedState = components.queryItems?.first(where: { $0.name == "state" })?.value,
                      returnedState == state else {
                    continuation.resume(throwing: SpotifyError.authenticationFailed)
                    return
                }
                
                // Exchange the code for an access token
                Task {
                    do {
                        let token = try await self.exchangeCodeForToken(code: code, redirectUri: redirectUri)
                        continuation.resume(returning: token)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            
            if !session.start() {
                continuation.resume(throwing: SpotifyError.authenticationFailed)
            }
        }
    }
    
    private func exchangeCodeForToken(code: String, redirectUri: String) async throws -> String {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let auth = "\(clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUri
        ]
        request.httpBody = body.map { "\($0)=\($1)" }.joined(separator: "&").data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.authenticationFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else {
            throw SpotifyError.invalidResponse
        }
        
        userAccessToken = token
        return token
    }
    
    func createPlaylist(from setlist: Setlist) async throws {
        let token = try await authenticateUser()
        
        // First get the user's Spotify ID
        let userProfileUrl = URL(string: "https://api.spotify.com/v1/me")!
        var profileRequest = URLRequest(url: userProfileUrl)
        profileRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (profileData, profileResponse) = try await URLSession.shared.data(for: profileRequest)
        
        guard let httpResponse = profileResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: profileData) as? [String: Any],
              let userId = json["id"] as? String else {
            throw SpotifyError.invalidResponse
        }
        
        // Create a list of all songs from the setlist
        var allSongs: [Song] = []
        for set in setlist.sets.set {
            allSongs.append(contentsOf: set.song)
        }
        
        // Search for each song and collect their URIs
        var trackUris: [String] = []
        for song in allSongs {
            let searchTerm = "\(song.name) \(setlist.artist.name)"
            let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedTerm)&type=track&limit=1")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SpotifyError.searchFailed
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tracks = json["tracks"] as? [String: Any],
                  let items = tracks["items"] as? [[String: Any]],
                  let firstTrack = items.first,
                  let uri = firstTrack["uri"] as? String else {
                continue
            }
            
            trackUris.append(uri)
        }
        
        guard !trackUris.isEmpty else {
            throw SpotifyError.noMatchFound
        }
        
        // Create the playlist
        let createPlaylistUrl = URL(string: "https://api.spotify.com/v1/users/\(userId)/playlists")!
        var createRequest = URLRequest(url: createPlaylistUrl)
        createRequest.httpMethod = "POST"
        createRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let playlistName = "GigBuddy: \(setlist.artist.name) at \(setlist.venue.name)"
        let description = "Setlist from \(setlist.formattedDate) at \(setlist.venue.name), \(setlist.venue.city.name)"
        let createBody: [String: Any] = [
            "name": playlistName,
            "description": description,
            "public": false
        ]
        createRequest.httpBody = try? JSONSerialization.data(withJSONObject: createBody)
        
        let (createData, createResponse) = try await URLSession.shared.data(for: createRequest)
        
        guard let httpResponse = createResponse as? HTTPURLResponse,
              httpResponse.statusCode == 201,
              let json = try? JSONSerialization.jsonObject(with: createData) as? [String: Any],
              let playlistId = json["id"] as? String else {
            throw SpotifyError.playlistCreationFailed
        }
        
        // Add tracks to the playlist
        let addTracksUrl = URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)/tracks")!
        var addRequest = URLRequest(url: addTracksUrl)
        addRequest.httpMethod = "POST"
        addRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        addRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let addBody: [String: Any] = ["uris": trackUris]
        addRequest.httpBody = try? JSONSerialization.data(withJSONObject: addBody)
        
        let (_, addResponse) = try await URLSession.shared.data(for: addRequest)
        
        guard let httpResponse = addResponse as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw SpotifyError.playlistCreationFailed
        }
    }
} 