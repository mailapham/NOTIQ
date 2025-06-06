//
//  calendarView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI

struct calendarView: View {
    @ObservedObject var RemindInfo: remindInfo
    
    @State private var isDeleting = false
    @State private var eventToDelete: eventModel?
    @State private var showDeleteAlert = false
    @State private var selectedDate: Date = Date()
    @State private var showingAddEventSheet = false
    @State private var eventToEdit: eventModel?
    @State private var editingEvent: eventModel?
    
    @State private var eventsForSelectedDate: [eventModel] = []
    @State private var tasksForSelectedDate: [remindModel] = []
    
    let calendar = Calendar.current
    
    // weekdays with unique identifiers
    let weekdays = [
        (id: "sun", label: "S"),
        (id: "mon", label: "M"),
        (id: "tue", label: "T"),
        (id: "wed", label: "W"),
        (id: "thu", label: "T"),
        (id: "fri", label: "F"),
        (id: "sat", label: "S")
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    // calendar header
                    HStack {
                        Button(action: {
                            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? Date()
                            updateTasksAndEventsForSelectedDate()
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundColor(Color(hex: "#91A7D0"))
                        }
                        
                        Spacer()
                        
                        Text("\(selectedDate, formatter: monthFormatter)")
                            .font(.title)
                            .bold()
                        
                        Spacer()
                        
                        Button(action: {
                            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? Date()
                            updateTasksAndEventsForSelectedDate()
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundColor(Color(hex: "#91A7D0"))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // weekday headers
                    HStack {
                        ForEach(weekdays, id: \.id) { day in
                            Text(day.label)
                                .frame(maxWidth: .infinity)
                                .fontWeight(.medium)
                        }
                    }
                    .font(.headline)
                    .padding(.bottom, 5)
                    .padding(.horizontal)
                    .padding(.top, 3)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(getDaysInMonth(), id: \.id) { day in
                            VStack {
                                if let date = day.date {
                                    Button(action: {
                                        selectedDate = date
                                        updateTasksAndEventsForSelectedDate()
                                    }) {
                                        VStack {
                                            Text("\(calendar.component(.day, from: date))")
                                                .font(.system(size: 16))
                                                .foregroundColor(
                                                    calendar.isDate(date, inSameDayAs: Date()) ?
                                                    Color(hex: "#91A7D0") :
                                                    (calendar.isDate(date, inSameDayAs: selectedDate) ?
                                                     Color.white : Color.primary)
                                                )
                                                .frame(width: 35, height: 35)
                                                .background(
                                                    calendar.isDate(date, inSameDayAs: selectedDate) ?
                                                    Circle().fill(Color(hex: "#C9D7ED")) :
                                                    Circle().fill(Color.clear)
                                                )
                                            
                                            // event/task indicator dot
                                            if eventsOnDate(date) || tasksOnDate(date) {
                                                Circle()
                                                    .fill(
                                                        eventsOnDate(date) && tasksOnDate(date) ?
                                                        Color(hex: "722F9C").opacity(0.3) :
                                                        (eventsOnDate(date) ?
                                                            Color(hex: "#3C5E95").opacity(0.3) :
                                                            Color(hex: "#FCD12A").opacity(0.4)
                                                        )
                                                    )
                                                    .frame(width: 6, height: 6)
                                            } else {
                                                Circle()
                                                    .fill(Color.clear)
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                    }
                                } else {
                                    Text("")
                                        .frame(width: 35, height: 35)
                                    Spacer()
                                        .frame(height: 6)
                                }
                            }
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
                
                Divider()
                
                ZStack(alignment: .bottomTrailing) {
                    // display events and tasks for selected date
                    if eventsForSelectedDate.isEmpty && tasksForSelectedDate.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding(.top, 30)
                            
                            Text("No Events or Tasks")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Nothing scheduled for this day")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top)
                    } else {
                        List {
                            // events section
                            if !eventsForSelectedDate.isEmpty {
                                Section {
                                    Text("Events")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .padding(.top, 5)
                                        .padding(.leading)
                                        .listRowInsets(EdgeInsets())
                                    
                                    ForEach(eventsForSelectedDate) { event in
                                        eventCard(event: event)
                                            .listRowInsets(EdgeInsets())
                                            .listRowSeparator(.hidden)
                                            .padding(.vertical, 4)
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    eventToDelete = event
                                                    showDeleteAlert = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash.fill")
                                                }
                                                
                                                Button {
                                                    editingEvent = event
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(.blue)
                                            }
                                            .listRowBackground(Color.clear)
                                    }
                                }
                            }
                            
                            // tasks section
                            if !tasksForSelectedDate.isEmpty {
                                Section {
                                    Text("Tasks")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .padding(.top, 5)
                                        .padding(.leading)
                                        .listRowInsets(EdgeInsets())
                                    
                                    ForEach(tasksForSelectedDate) { task in
                                        taskCard(task: task)
                                            .listRowInsets(EdgeInsets())
                                            .listRowSeparator(.hidden)
                                            .padding(.vertical, 4)
                                            .listRowBackground(Color.clear)
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    
                    // add event button
                    Button(action: {
                        showingAddEventSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "#91A7D0"))
                            .padding(.vertical)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .alert("Deleting Event", isPresented:$showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("OK", role: .destructive) {
                if let event = eventToDelete {
                    RemindInfo.deleteEvent(id: event.id)
                    updateTasksAndEventsForSelectedDate()
                }
                eventToDelete = nil
            }
        }, message: {
            Text("Are you sure you want to delete this event?")
        })
        .sheet(item: $editingEvent) { event in
            addEvent(RemindInfo: RemindInfo, eventToEdit: event)
        }
        .sheet(isPresented: $showingAddEventSheet) {
            addEvent(RemindInfo: RemindInfo, eventToEdit: nil)
        }
        .onChange(of: selectedDate) { _, _ in
            updateTasksAndEventsForSelectedDate()
        }
        .onAppear {
            updateTasksAndEventsForSelectedDate()
        }
    }
    
    // event card view
    private func eventCard(event: eventModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    /*Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#3C5E95").opacity(0.8))
                        .font(.system(size: 16))*/
                    
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if event.isFlagged {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                }
                
                if !event.descriptionText.isEmpty {
                    Text(event.descriptionText)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if event.isAllDay {
                        Text("All day")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if let start = event.startDate, let end = event.endDate {
                        Text("\(formatTime(start)) - \(formatTime(end))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text(formatTime(event.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if let location = event.location, !location.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            
                            if let address = event.address, !address.isEmpty {
                                Text(address)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .frame(height: 125)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // task card view
    private func taskCard(task: remindModel) -> some View {
        HStack {
            Button(action: {
                if task.isCompleted {
                    RemindInfo.markTaskAsUndone(task: task)
                } else {
                    RemindInfo.markTaskAsDone(task: task)
                }
                updateTasksAndEventsForSelectedDate()
            }) {
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.trailing, 5)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    /*Image(systemName: "checklist")
                        .foregroundColor(Color(hex: "#3C5E95").opacity(0.8))
                        .font(.system(size: 16))*/
                    
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? .gray : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                    
                    if task.isFlagged {
                        Image(systemName: "flag.fill")
                            .foregroundColor(task.isCompleted ? .gray : .red)
                            .font(.system(size: 12))
                    }
                }
                
                Text(task.course)
                    .font(.subheadline)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .lineLimit(1)
                
                if !task.descriptionText.isEmpty {
                    Text(task.descriptionText)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatTime(task.dueDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if isOverdue(task) {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                if let location = task.location, !location.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            
                            if let address = task.address, !address.isEmpty {
                                Text(address)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .frame(height: 125)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // helper structures
    struct CalendarDay: Identifiable {
        let id: String
        let date: Date?
        
        init(date: Date?, index: Int) {
            self.date = date
            self.id = date != nil ? date!.formatted(date: .complete, time: .omitted) + "\(index)" : "empty-\(UUID().uuidString)"
        }
    }
    
    // helper functions
    private func getDaysInMonth() -> [CalendarDay] {
        let range = calendar.range(of: .day, in: .month, for: selectedDate) ?? 1..<32
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        let totalDaysInMonth = range.count
        
        var days: [CalendarDay] = []
        
        // adding empty cells before first day of month
        for i in 0..<firstWeekday {
            days.append(CalendarDay(date: nil, index: i))
        }
        
        // days of the month
        for i in 1...totalDaysInMonth {
            let day = calendar.date(byAdding: .day, value: i - 1, to: firstDayOfMonth)
            days.append(CalendarDay(date: day, index: i + firstWeekday))
        }
        
        return days
    }
    
    private func eventsOnDate(_ date: Date) -> Bool {
        return RemindInfo.events.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func tasksOnDate(_ date: Date) -> Bool {
        // check both active and completed tasks
        let allTasks = RemindInfo.tasks + RemindInfo.completedTasks
        return allTasks.contains { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }
    
    private func isOverdue(_ task: remindModel) -> Bool {
        return !task.isCompleted && task.dueDate < Date()
    }
    
    // sorting from flagged -> earliest date
    private func updateTasksAndEventsForSelectedDate() {
        let filteredEvents = RemindInfo.events.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        let filteredTasks = RemindInfo.tasksForSelectedDate(selectedDate)
        
        eventsForSelectedDate = filteredEvents.sorted {
            if $0.isFlagged != $1.isFlagged {
                return $0.isFlagged
            }
            let date1 = $0.startDate ?? $0.date
            let date2 = $1.startDate ?? $1.date
            return date1 < date2
        }
        
        tasksForSelectedDate = filteredTasks.sorted {
            if $0.isFlagged != $1.isFlagged {
                return $0.isFlagged
            }
            return $0.dueDate < $1.dueDate
        }
    }
    
    // formatting time
    private func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
}

// formatting for dates
let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
}()

let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d, yyyy"
    return formatter
}()
