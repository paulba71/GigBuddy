//
//  ContentView.swift
//  GigBuddy
//
//  Created by Paul Barnes on 23/04/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GigViewModel()
    @State private var showingAddGig = false
    @State private var showingTicketmasterSearch = false
    @State private var showingAbout = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $viewModel.selectedView) {
                    Text("List").tag(GigViewModel.ViewType.list)
                    Text("Calendar").tag(GigViewModel.ViewType.calendar)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if viewModel.selectedView == .list {
                    GigListView(viewModel: viewModel)
                } else {
                    GigCalendarView(viewModel: viewModel)
                }
            }
            .navigationTitle("GigBuddy")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingAbout = true }) {
                            Label("About", systemImage: "info.circle")
                        }
                        Button(action: { showingSettings = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddGig = true }) {
                            Label("Add Manually", systemImage: "plus")
                        }
                        Button(action: { showingTicketmasterSearch = true }) {
                            Label("Search Ticketmaster", systemImage: "magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGig) {
                GigDetailView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingTicketmasterSearch) {
                TicketmasterSearchView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAbout) {
                NavigationView {
                    AboutView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    SettingsView(viewModel: viewModel)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
