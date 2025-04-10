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
            VStack {
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
                
                // weekday headers - fixed to use unique IDs
                HStack {
                    ForEach(weekdays, id: \.id) { day in
                        Text(day.label)
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.headline)
                .padding(.bottom, 5)
                
                // calendar grid - using unique IDs
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(getDaysInMonth(), id: \.id) { day in
                        VStack {
                            if let date = day.date {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.subheadline)
                                    .padding(5)
                                    .foregroundColor(
                                        calendar.isDate(date, inSameDayAs: Date()) ? Color.red : Color.black
                                    )
                                    .background(
                                        calendar.isDate(date, inSameDayAs: selectedDate) ? Color.white : Color.clear
                                    )
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedDate = date
                                        updateTasksAndEventsForSelectedDate()
                                    }

                                // create a marker if there is an event/task
                                if eventsOnDate(date) || tasksOnDate(date) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 4)
                                }
                            } else {
                                Text("")
                            }
                        }
                    }
                }
                .padding(.bottom)

                // display the events and tasks for a selected date
                if eventsForSelectedDate.isEmpty && tasksForSelectedDate.isEmpty {
                    Text("No Events or Tasks")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        // section for events
                        if !eventsForSelectedDate.isEmpty {
                            Section(header: Text("Events")) {
                                ForEach(eventsForSelectedDate) { event in
                                    EventRowView(event: event, isDeleting: $isDeleting, onDelete: {
                                        eventToDelete = event
                                        showDeleteAlert = true
                                    }, onEdit: {
                                        eventToEdit = event
                                        showingAddEventSheet = true
                                    })
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            eventToDelete = event
                                            showDeleteAlert = true
                                        }) {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        .tint(.red)

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
                        }
                        
                        // section for tasks
                        if !tasksForSelectedDate.isEmpty {
                            Section(header: Text("Tasks")) {
                                ForEach(tasksForSelectedDate) { task in
                                    CalendarTaskRowView(task: task, onToggleComplete: {})
                                }
                            }
                        }
                    }
                }
                
                // adding and deleting events, editing privileges
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
            .background(Color(UIColor.systemGray6))
            .navigationBarTitle("Calendar", displayMode: .inline)
            .onChange(of: selectedDate) { _, _ in
                updateTasksAndEventsForSelectedDate()
            }
        }
        .onAppear {
            updateTasksAndEventsForSelectedDate()
        }
    }
    
    private func toggleTaskCompletion(_ task: remindModel) {
        if task.isCompleted {
            RemindInfo.markTaskAsUndone(task: task)
        } else {
            RemindInfo.markTaskAsDone(task: task)
        }
        updateTasksAndEventsForSelectedDate()
    }
    
    // day structure to ensure unique IDs
    struct CalendarDay: Identifiable {
        let id: String
        let date: Date?
        
        init(date: Date?, index: Int) {
            self.date = date
            self.id = date != nil ? date!.formatted(date: .complete, time: .omitted) + "\(index)" : "empty-\(UUID().uuidString)"
        }
    }
    
    // helper functions for gathering calendar data
    private func getDaysInMonth() -> [CalendarDay] {
        let range = calendar.range(of: .day, in: .month, for: selectedDate) ?? 1..<32
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        let totalDaysInMonth = range.count
        
        var days: [CalendarDay] = []
        
        // empty cells before first day of month
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
    
    private func updateTasksAndEventsForSelectedDate() {
        eventsForSelectedDate = RemindInfo.events.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        tasksForSelectedDate = RemindInfo.tasksForSelectedDate(selectedDate)
    }
}

// task row view specifically for calendar view
struct CalendarTaskRowView: View {
    let task: remindModel
    let onToggleComplete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                Text(task.course)
                    .font(.subheadline)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(task.isCompleted ? .gray : .gray)
                
                Text("Due: \(formatTime(task.dueDate))")
                    .font(.subheadline)
                    .foregroundColor(task.isCompleted ? .gray : (isOverdue(task) ? .red : .gray))
                
                if let location = task.location {
                    Text("Location: \(location)")
                        .font(.subheadline)
                        .foregroundColor(task.isCompleted ? .gray : .gray)
                }
            }
            
            Spacer()
            
            if task.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundColor(task.isCompleted ? .gray : .red)
            }
        }
    }
    
    private func isOverdue(_ task: remindModel) -> Bool {
        return !task.isCompleted && task.dueDate < Date()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// formatting months
let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
}()

// creating the tableView lists for events
struct EventRowView: View {
    let event: eventModel
    @Binding var isDeleting: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.gray)

                if event.isAllDay {
                    Text("All-Day")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let startDate = event.startDate, let endDate = event.endDate {
                    Text("\(formatTime(startDate)) - \(formatTime(endDate))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if let location = event.location {
                    Text("Location: \(location)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if event.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
