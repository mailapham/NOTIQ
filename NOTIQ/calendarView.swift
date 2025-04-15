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
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 0) {
                        // calendar header
                        HStack {
                            Button(action: {
                                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? Date()
                                updateTasksAndEventsForSelectedDate()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
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
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
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
                        
                        // calendar grid
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
                                                        Color.red :
                                                        (calendar.isDate(date, inSameDayAs: selectedDate) ?
                                                         Color.white : Color.primary)
                                                    )
                                                    .frame(width: 35, height: 35)
                                                    .background(
                                                        calendar.isDate(date, inSameDayAs: selectedDate) ?
                                                        Circle().fill(Color(hex: "#3C5E95")) :
                                                        Circle().fill(Color.clear)
                                                    )
                                                
                                                // event/task indicator dot
                                                if eventsOnDate(date) || tasksOnDate(date) {
                                                    Circle()
                                                        .fill(
                                                            eventsOnDate(date) && tasksOnDate(date) ?
                                                            Color.purple : (eventsOnDate(date) ?
                                                                          Color(hex: "#3C5E95") :
                                                                          Color(hex: "#FCD12A"))
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
                        
                        Divider()
                        
                        // selected date header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(selectedDate, formatter: dayFormatter)")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text("\(eventsForSelectedDate.count) Events, \(tasksForSelectedDate.count) Tasks")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
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
                            }
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 100)
                        } else {
                            // events section
                            if !eventsForSelectedDate.isEmpty {
                                Text("Events")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .padding(.top)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVStack {
                                    ForEach(eventsForSelectedDate) { event in
                                        eventCard(event: event)
                                            .padding(.vertical, 4)
                                            .swipeActions {
                                                Button(role: .destructive, action: {
                                                    eventToDelete = event
                                                    showDeleteAlert = true
                                                }) {
                                                    Label("Delete", systemImage: "trash.fill")
                                                }
                                                Button(action: {
                                                    eventToEdit = event
                                                    showingAddEventSheet = true
                                                }) {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(.blue)
                                            }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }

                            // tasks section
                            if !tasksForSelectedDate.isEmpty {
                                if !eventsForSelectedDate.isEmpty {
                                    Divider()
                                        .padding(.vertical, 10)
                                }
                                
                                Text("Tasks")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ForEach(tasksForSelectedDate) { task in
                                    taskCard(task: task)
                                }
                            }
                            
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
                
                // add event button
                HStack {
                    Button(action: {
                        eventToEdit = nil
                        showingAddEventSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "#3C5E95"))
                            .padding(.vertical)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .alert("Deleting Event", isPresented: $showDeleteAlert, actions: {
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
            .sheet(isPresented: $showingAddEventSheet) {
                addEvent(RemindInfo: RemindInfo, eventToEdit: eventToEdit)
            }
            .onChange(of: selectedDate) { _, _ in
                updateTasksAndEventsForSelectedDate()
            }
            .onAppear {
                updateTasksAndEventsForSelectedDate()
            }
        }
    }
    
    // event card view
    private func eventCard(event: eventModel) -> some View {
        Button(action: {
            eventToEdit = event
            showingAddEventSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "#3C5E95"))
                            .font(.system(size: 16))
                        
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
                    .strikethrough(task.isCompleted)
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
