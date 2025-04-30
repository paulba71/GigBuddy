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
    @State private var selectedTab = 1
    @State private var hasLoadedInitialEvents = false
    @State private var selectedRegion = TicketmasterRegion.allRegions.first { $0.countryCode == "IE" }! // Default to Ireland
    @State private var isSearching = false
    
    private let ticketmasterService = TicketmasterService(apiKey: "Ke3bgfVXyABFsJ648DoLHcUDHkhCTmsG")
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Region", selection: $selectedRegion) {
                    ForEach(TicketmasterRegion.allRegions, id: \.self) { region in
                        Text(region.name).tag(region)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                Picker("View Mode", selection: $selectedTab) {
                    Text("Search").tag(1)
                    Text("Upcoming").tag(0)
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
                } else if let error = errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Try Again") {
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
            .navigationTitle("Add Event")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onChange(of: searchText) { newValue in
                if selectedTab == 1 && !newValue.isEmpty {
                    Task {
                        await performSearch()
                    }
                } else if selectedTab == 1 && newValue.isEmpty {
                    events = []
                }
            }
            .onChange(of: selectedTab) { newValue in
                Task {
                    if newValue == 0 {
                        await loadUpcomingEvents()
                    } else if !searchText.isEmpty {
                        await performSearch()
                    }
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
            .onAppear {
                // Load initial events when view appears
                Task {
                    if selectedTab == 0 {
                        await loadUpcomingEvents()
                    }
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
                in: [selectedRegion]
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
            events = try await ticketmasterService.searchEvents(
                keyword: searchText,
                in: [selectedRegion]
            )
            print("✅ Successfully loaded \(events.count) search results for '\(searchText)'")
        } catch {
            print("❌ Error searching events: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct RegionSelector: View {
    @Binding var selectedRegions: Set<TicketmasterRegion>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Search Regions")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(TicketmasterRegion.allRegions.filter { $0.countryCode == "IE" || $0.countryCode == "GB" }, id: \.self) { region in
                        RegionButton(
                            region: region,
                            isSelected: selectedRegions.contains(region),
                            action: {
                                if selectedRegions.contains(region) {
                                    selectedRegions.remove(region)
                                } else {
                                    selectedRegions.insert(region)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RegionButton: View {
    let region: TicketmasterRegion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(region.name)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct ErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack {
            Text(error)
                .foregroundColor(.red)
            Button("Try Again", action: retryAction)
        }
    }
}

struct EventsListView: View {
    let events: [TicketmasterEvent]
    let selectedTab: Int
    let searchText: String
    let onEventTap: (TicketmasterEvent) -> Void
    let onRefresh: () async -> Void
    
    var body: some View {
        Group {
            if events.isEmpty {
                EmptyStateView(selectedTab: selectedTab, searchText: searchText)
            } else {
                List(events) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventRow(event: event)
                    }
                    .onTapGesture {
                        onEventTap(event)
                    }
                }
                .refreshable {
                    await onRefresh()
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let selectedTab: Int
    let searchText: String
    
    var body: some View {
        VStack {
            Image(systemName: selectedTab == 0 ? "calendar" : "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(selectedTab == 0 ? "No upcoming events found nearby" : (searchText.isEmpty ? "Enter a search term" : "No search results"))
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .frame(maxHeight: .infinity)
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
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search events...", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .onSubmit(onSearch)
                    .focused($isFocused)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        isFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    isFocused = false
                    onSearch()
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
            
            if isFocused {
                Button("Done") {
                    isFocused = false
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, isFocused ? 8 : 0)
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
                Text("\(venue.name ?? "Unknown Venue")\(venue.city?.name != nil ? ", \(venue.city!.name)" : "")")
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
                            Text(venue.name ?? "Unknown Venue")
                                .font(.headline)
                            Text("\(venue.city?.name ?? "Unknown City")")
                                .foregroundColor(.secondary)
                            if let address = venue.address {
                                Text(address.line1)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if let dateTime = event.dates.start.dateTime {
                        Text(formatDate(dateTime))
                            .font(.headline)
                    } else {
                        Text(event.dates.start.localDate)
                            .font(.headline)
                    }
                    
                    if let urlString = event.url, let url = URL(string: urlString) {
                        Link("Buy Tickets", destination: url)
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                    }
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
