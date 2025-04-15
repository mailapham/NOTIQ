//
//  homeView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/28/25.
//

import SwiftUI

struct homeView: View {
    @ObservedObject var RemindInfo: remindInfo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // section for "today's schedule"
                    if !todaysItems.isEmpty {
                        Text("Today's Schedule")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(todaysItems.indices, id: \.self) { index in
                            itemCard(item: todaysItems[index])
                        }
                        
                        Divider()
                            .padding(.vertical, 10)
                    }
                    
                    // section for "coming up" schedule - 3 days in advance
                    if !upcomingItems.isEmpty {
                        Text("Coming Up")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(upcomingItems.indices, id: \.self) { index in
                            itemCard(item: upcomingItems[index])
                        }
                    }
                    
                    // default view for no items scheduled
                    if todaysItems.isEmpty && upcomingItems.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                                .frame(height: 120)
                            
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No upcoming events or tasks")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Text("Your notifications will appear here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    // enum to unify tasks and events under a common type with shared properties
    private enum ScheduleItem: Identifiable {
        case task(remindModel)
        case event(eventModel)
        
        var id: UUID {
            switch self {
            case .task(let task): return task.id
            case .event(let event): return event.id
            }
        }
        
        var title: String {
            switch self {
            case .task(let task): return task.title
            case .event(let event): return event.title
            }
        }
        
        var description: String {
            switch self {
            case .task(let task): return task.descriptionText
            case .event(let event): return event.descriptionText
            }
        }
        
        var itemDate: Date {
            switch self {
            case .task(let task): return task.dueDate
            case .event(let event): return event.date
            }
        }
        
        var location: String? {
            switch self {
            case .task(let task): return task.location
            case .event(let event): return event.location
            }
        }
        
        var isFlagged: Bool {
            switch self {
            case .task(let task): return task.isFlagged
            case .event(let event): return event.isFlagged
            }
        }
    }
    
    // get all active tasks for "today"
    private var todaysItems: [ScheduleItem] {
        let calendar = Calendar.current
        let today = Date()
        
        // uncompleted tasks list
        let todaysTasks = RemindInfo.tasks
            .filter { calendar.isDate($0.dueDate, inSameDayAs: today) }
            .map { ScheduleItem.task($0) }
        
        // events list
        let todaysEvents = RemindInfo.events
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .map { ScheduleItem.event($0) }
        
        // sorting by flag/date
        let combined = todaysTasks + todaysEvents
        return combined.sorted {
            if $0.isFlagged != $1.isFlagged {
                return $0.isFlagged
            }
            return $0.itemDate < $1.itemDate
        }
    }
    
    // get upcoming items for next 3 days
    private var upcomingItems: [ScheduleItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let threeDaysFromNow = calendar.date(byAdding: .day, value: 4, to: today) else {
            return []
        }
        
        // uncompleted tasks list
        let upcomingTasks = RemindInfo.tasks
            .filter {
                let taskDate = calendar.startOfDay(for: $0.dueDate)
                return taskDate > today && taskDate < threeDaysFromNow
            }
            .map { ScheduleItem.task($0) }
        
        // events list
        let upcomingEvents = RemindInfo.events
            .filter {
                let eventDate = calendar.startOfDay(for: $0.date)
                return eventDate > today && eventDate < threeDaysFromNow
            }
            .map { ScheduleItem.event($0) }
        
        // sorting by flag/date
        let combined = upcomingTasks + upcomingEvents
        return combined.sorted {
            let firstDate = calendar.startOfDay(for: $0.itemDate)
            let secondDate = calendar.startOfDay(for: $1.itemDate)
            
            if firstDate != secondDate {
                return firstDate < secondDate
            }
            
            if $0.isFlagged != $1.isFlagged {
                return $0.isFlagged
            }
            
            return $0.itemDate < $1.itemDate
        }
    }
    
    // card view for displaying both events and tasks
    @ViewBuilder
    private func itemCard(item: ScheduleItem) -> some View {
        switch item {
        case .task(let task):
            taskView(task: task)
        case .event(let event):
            eventView(event: event)
        }
    }
    
    // task card view
    private func taskView(task: remindModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if task.isFlagged {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                }
                
                Text(task.course)
                    .font(.subheadline)
                    .foregroundColor(.primary)
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
                    
                    if task.dueDate < Date() {
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
            
            Text("Task")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#FCD12A").opacity(0.2))
                .foregroundColor(Color(hex: "#FCD12A"))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // event card view
    private func eventView(event: eventModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#3C5E95"))
                        .font(.system(size: 16))
                    
                    Text(event.title)
                        .font(.headline)
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
            
            Text("Event")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#3C5E95").opacity(0.2))
                .foregroundColor(Color(hex: "#3C5E95"))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // formatting time
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()

        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "h:mm a"
            return "Today at \(dateFormatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            dateFormatter.dateFormat = "h:mm a"
            return "Tomorrow at \(dateFormatter.string(from: date))"
        } else {
            dateFormatter.dateFormat = "EEE, MMM d 'at' h:mm a"
            return dateFormatter.string(from: date)
        }
    }
}
