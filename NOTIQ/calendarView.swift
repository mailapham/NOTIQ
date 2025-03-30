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
    
    var body: some View {
        NavigationView {
            VStack {
                // navigation header
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
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.headline)
                .padding(.bottom, 5)
                
                // calendar grid - inserts actual days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(getDaysInMonth(), id: \.self) { day in
                        VStack {
                            if let validDay = day {
                                Text("\(calendar.component(.day, from: validDay))")
                                    .font(.subheadline)
                                    .padding(5)
                                    .foregroundColor(
                                        // today's date = red, else = black
                                        calendar.isDate(validDay, inSameDayAs: Date()) ? Color.red : Color.black
                                    )
                                    .background(
                                        // user selected date = white circle
                                        calendar.isDate(validDay, inSameDayAs: selectedDate) ? Color.white.opacity(0.3) : Color.clear
                                    )
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedDate = validDay
                                        updateTasksAndEventsForSelectedDate()
                                    }

                                // create a marker if there is an event/task
                                if eventsOnDate(validDay) || tasksOnDate(validDay) {
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
                                }
                            }
                        }
                        
                        // section for tasks
                        if !tasksForSelectedDate.isEmpty {
                            Section(header: Text("Tasks")) {
                                ForEach(tasksForSelectedDate) { task in
                                    RemindRowView(task: task, isDeleting: $isDeleting, onDelete: {
                                    }, onEdit: {
                                    })
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
        }
        .onAppear {
            updateTasksAndEventsForSelectedDate()
        }
    }
    
    // helper functions for gathering calendar data
    private func getDaysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: selectedDate) ?? 1..<32
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        let totalDaysInMonth = range.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for i in 1...totalDaysInMonth {
            let day = calendar.date(byAdding: .day, value: i - 1, to: firstDayOfMonth)
            days.append(day)
        }
        
        return days
    }
    
    private func eventsOnDate(_ date: Date) -> Bool {
        return RemindInfo.events.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func tasksOnDate(_ date: Date) -> Bool {
        return RemindInfo.tasks.contains { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }
    
    private func updateTasksAndEventsForSelectedDate() {
        eventsForSelectedDate = RemindInfo.events.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        tasksForSelectedDate = RemindInfo.tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }

    private func deleteEvent(at offsets: IndexSet) {
        offsets.forEach { index in
            let event = RemindInfo.events[index]
            RemindInfo.deleteEvent(id: event.id)
        }
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
                } else {
                        Text("")
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
}
