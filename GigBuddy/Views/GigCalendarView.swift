import SwiftUI

struct GigCalendarView: View {
    @ObservedObject var viewModel: GigViewModel
    @State private var selectedDate = Date()
    
    var gigsForSelectedDate: [Gig] {
        viewModel.gigs.filter { gig in
            Calendar.current.isDate(gig.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        VStack {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            
            if gigsForSelectedDate.isEmpty {
                Text("No gigs scheduled for this date")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(gigsForSelectedDate) { gig in
                    NavigationLink(destination: GigDetailView(viewModel: viewModel, gig: gig)) {
                        VStack(alignment: .leading) {
                            Text(gig.artist)
                                .font(.headline)
                            Text(gig.location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(gig.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < gig.rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
} 