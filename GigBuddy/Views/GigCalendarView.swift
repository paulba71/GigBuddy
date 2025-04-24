import SwiftUI

// Add Array extension for rotation
extension Array {
    mutating func rotate(by offset: Int) {
        let offset = (offset % count + count) % count // Normalize the offset
        let slice1 = self[..<offset]
        let slice2 = self[offset...]
        self = Array(slice2 + slice1)
    }
}

struct GigCalendarView: View {
    @ObservedObject var viewModel: GigViewModel
    @State private var selectedDate = Date()
    
    var gigsForSelectedDate: [Gig] {
        viewModel.gigs.filter { gig in
            Calendar.current.isDate(gig.date, inSameDayAs: selectedDate)
        }
    }
    
    // Set of dates that have gigs for efficient lookup
    var datesWithGigs: Set<Date> {
        Set(viewModel.gigs.map { gig in
            Calendar.current.startOfDay(for: gig.date)
        })
    }
    
    var body: some View {
        VStack {
            CustomCalendarView(
                selectedDate: $selectedDate,
                datesWithGigs: datesWithGigs
            )
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
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let datesWithGigs: Set<Date>
    
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    private var daysOfWeek: [String] {
        let formatter = DateFormatter()
        formatter.locale = .current
        guard var weekdaySymbols = formatter.veryShortWeekdaySymbols else {
            return []
        }
        // Rotate array to match calendar's first weekday
        let firstWeekday = calendar.firstWeekday
        let rotatedAmount = firstWeekday - 1 // Convert to 0-based index
        let rotatedSymbols = Array(weekdaySymbols[rotatedAmount...] + weekdaySymbols[..<rotatedAmount])
        return rotatedSymbols
    }
    
    var body: some View {
        VStack {
            // Month selector
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.title2)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // Days of week header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasGig: datesWithGigs.contains(calendar.startOfDay(for: date))
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = calendar.timeZone
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            if currentDate >= monthInterval.start && currentDate < monthInterval.end {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasGig: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .foregroundColor(hasGig ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hasGig ? Color.accentColor.opacity(0.8) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : (hasGig ? Color.accentColor : Color.clear), lineWidth: isSelected ? 2 : 1)
            )
    }
} 