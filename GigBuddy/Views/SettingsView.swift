import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var gigViewModel: GigViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var deletionMode: DeletionMode = .all
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var showingImportError = false
    @State private var importError: Error?
    @State private var showingExportError = false
    @State private var exportError: Error?
    @State private var exportURL: URL?
    
    enum DeletionMode {
        case all
        case future
        
        var title: String {
            switch self {
            case .all: return "Delete All Events"
            case .future: return "Delete Future Events"
            }
        }
        
        var message: String {
            switch self {
            case .all: return "Are you sure you want to delete all events? This action cannot be undone."
            case .future: return "Are you sure you want to delete all future events? This action cannot be undone."
            }
        }
    }
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Stepper(value: $gigViewModel.defaultTicketCount, in: 0...10) {
                        HStack {
                            Text("Default Tickets")
                            Spacer()
                            Text("\(gigViewModel.defaultTicketCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Default Settings")
                } footer: {
                    Text("This number of tickets will be automatically set when adding new events. Set to 0 to manually enter ticket count for each event.")
                }
                
                Section {
                    Button {
                        prepareAndShowExporter()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Events")
                        }
                    }
                    
                    Button {
                        showingImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Events")
                        }
                    }
                } header: {
                    Text("Backup & Restore")
                } footer: {
                    Text("Export your events to a file for backup, or import events from a previous backup.")
                }
                
                Section {
                    Button(role: .destructive) {
                        deletionMode = .all
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Events")
                        }
                    }
                    
                    Button(role: .destructive) {
                        deletionMode = .future
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.minus")
                            Text("Delete Future Events")
                        }
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Deleting events cannot be undone. Your data will be permanently removed.")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert(deletionMode.title, isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    switch deletionMode {
                    case .all:
                        gigViewModel.deleteAllGigs()
                    case .future:
                        gigViewModel.deleteFutureGigs()
                    }
                }
            } message: {
                Text(deletionMode.message)
            }
            .alert("Import Error", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importError?.localizedDescription ?? "An unknown error occurred.")
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    
                    do {
                        try gigViewModel.importGigs(from: url)
                    } catch {
                        importError = error
                        showingImportError = true
                    }
                case .failure(let error):
                    importError = error
                    showingImportError = true
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: GigBuddyExport(fileURL: exportURL),
                contentType: UTType.json,
                defaultFilename: "gigbuddy-backup"
            ) { result in
                if case .failure(let error) = result {
                    exportError = error
                    showingExportError = true
                }
                // Clean up the temporary export URL
                if let url = exportURL {
                    try? FileManager.default.removeItem(at: url)
                }
                exportURL = nil
            }
            .alert("Export Error", isPresented: $showingExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportError?.localizedDescription ?? "An unknown error occurred while exporting events.")
            }
        }
    }
    
    private func prepareAndShowExporter() {
        do {
            let tempURL = documentsDirectory.appendingPathComponent("temp-gigbuddy-export.json")
            try gigViewModel.exportGigs(to: tempURL)
            exportURL = tempURL
            showingExporter = true
        } catch {
            exportError = error
            showingExportError = true
        }
    }
}

struct GigBuddyExport: FileDocument {
    let fileURL: URL?
    
    static var readableContentTypes: [UTType] { [.json] }
    
    init(fileURL: URL?) {
        self.fileURL = fileURL
    }
    
    init(configuration: ReadConfiguration) throws {
        fileURL = nil
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return .init(regularFileWithContents: data)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GigViewModel())
} 