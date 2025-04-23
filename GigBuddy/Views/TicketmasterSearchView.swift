import SwiftUI
import CoreLocation
import os

struct TicketmasterSearchView: View {
    @ObservedObject var viewModel: GigViewModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var events: [TicketmasterEvent] = []
    @State private var upcomingEvents: [TicketmasterEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var hasLoadedInitialEvents = false
    @State private var selectedRegion = TicketmasterRegion.allRegions[1] // Default to UK
    @State private var isSearching = false
    
    private let ticketmasterService = TicketmasterService(apiKey: "Ke3bgfVXyABFsJ648DoLHcUDHkhCTmsG")
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Region", selection: $selectedRegion) {
                    ForEach(TicketmasterRegion.allRegions) { region in
                        Text(region.name).tag(region)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                Picker("View Mode", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Search").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 1 {
                    SearchBar(text: $searchText, onSearch: {
                        Task {
                            await performSearch()
                        }
                    })
                    .padding(.horizontal)
                }
                
                if isLoading {
                    ProgressView("Loading events...")
                        .onAppear {
                            print("⚡️ LOADING STATE ACTIVATED ⚡️")
                            os_log("Loading state activated", type: .debug)
                        }
                } else if let error = errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Try Again") {
                            print("🔄 RETRY BUTTON TAPPED 🔄")
                            Task {
                                if selectedTab == 0 {
                                    await loadUpcomingEvents()
                                } else {
                                    await performSearch()
                                }
                            }
                        }
                    }
                } else {
                    let displayedEvents = selectedTab == 0 ? upcomingEvents : events
                    if displayedEvents.isEmpty {
                        VStack {
                            Image(systemName: selectedTab == 0 ? "calendar" : "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text(selectedTab == 0 ? "No upcoming events found nearby" : (searchText.isEmpty ? "Enter a search term" : "No search results"))
                                .foregroundColor(.secondary)
                                .padding(.top)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List(displayedEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRow(event: event)
                            }
                            .onTapGesture {
                                let gig = Gig(from: event)
                                viewModel.addGig(gig)
                                dismiss()
                            }
                        }
                        .refreshable {
                            if selectedTab == 0 {
                                await loadUpcomingEvents()
                            }
                        }
                    }
                }
            }
            .navigationTitle("GigBuddy")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onChange(of: searchText) { newValue in
                // Only perform search if in search tab and text is not empty
                if selectedTab == 1 && !newValue.isEmpty {
                    Task {
                        await performSearch()
                    }
                } else if selectedTab == 1 && newValue.isEmpty {
                    events = [] // Clear results when search is empty
                }
            }
            .onChange(of: selectedTab) { newValue in
                if newValue == 0 {
                    // Clear search when switching to upcoming
                    searchText = ""
                    events = []
                }
            }
            .onChange(of: locationManager.location) { _ in
                if selectedTab == 0 {
                    Task {
                        await loadUpcomingEvents()
                    }
                }
            }
            .onChange(of: selectedRegion) { _ in
                Task {
                    if selectedTab == 0 {
                        await loadUpcomingEvents()
                    } else if !searchText.isEmpty {
                        await performSearch()
                    }
                }
            }
            .task {
                print("🚀 VIEW APPEARED - LOADING INITIAL EVENTS 🚀")
                if !hasLoadedInitialEvents {
                    await loadUpcomingEvents()
                    hasLoadedInitialEvents = true
                }
            }
        }
    }
    
    private func loadUpcomingEvents() async {
        print("📍 STARTING TO LOAD UPCOMING EVENTS 📍")
        isLoading = true
        errorMessage = nil
        
        do {
            print("📱 Location Authorization Status: \(locationManager.authorizationStatus.rawValue)")
            print("📱 Location: \(String(describing: locationManager.location))")
            
            upcomingEvents = try await ticketmasterService.discoverUpcomingEvents(
                latitude: locationManager.location?.coordinate.latitude,
                longitude: locationManager.location?.coordinate.longitude,
                in: selectedRegion
            )
            print("✅ Successfully loaded \(upcomingEvents.count) upcoming events")
        } catch {
            print("❌ Error loading upcoming events: \(error.localizedDescription)")
            errorMessage = "Failed to load upcoming events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func performSearch() async {
        guard !searchText.isEmpty else {
            events = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            events = try await ticketmasterService.searchEvents(keyword: searchText, in: selectedRegion)
            print("✅ Successfully loaded \(events.count) search results for '\(searchText)'")
        } catch {
            print("❌ Error searching events: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search events...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .onSubmit(onSearch)
            
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
            }
        }
    }
}

struct EventRow: View {
    let event: TicketmasterEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = event.images.first(where: { $0.width > 500 })?.url ?? event.images.first?.url,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                }
            }
            
            Text(event.name)
                .font(.headline)
                .lineLimit(2)
            
            if let venue = event.embedded?.venues?.first {
                Text("\(venue.name), \(venue.city.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if let dateTime = event.dates.start.dateTime {
                Text(formatDate(dateTime))
                    .font(.caption)
            } else {
                Text(event.dates.start.localDate)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EventDetailView: View {
    let event: TicketmasterEvent
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = event.images.first(where: { $0.width > 1000 })?.url ?? event.images.first?.url,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(event.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let venue = event.embedded?.venues?.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(venue.name)
                                .font(.headline)
                            Text("\(venue.city.name)")
                                .foregroundColor(.secondary)
                            Text(venue.address.line1)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let dateTime = event.dates.start.dateTime {
                        Text(formatDate(dateTime))
                            .font(.headline)
                    } else {
                        Text(event.dates.start.localDate)
                            .font(.headline)
                    }
                    
                    Link("Buy Tickets", destination: URL(string: event.url)!)
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 
