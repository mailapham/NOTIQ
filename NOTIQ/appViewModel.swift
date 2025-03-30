//
//  appViewModel.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import Foundation
import SwiftUI

class remindInfo: ObservableObject {
    @Published var tasks: [remindModel] = []
    @Published var completedTasks: [remindModel] = []
    @Published var events: [eventModel] = []

    // task/reminder functions
    func addTask(title: String, course: String, description: String, dueDate: Date, location: String?, isFlagged: Bool) {
        let newTask = remindModel(
            title: title,
            course: course,
            description: description,
            dueDate: dueDate,
            location: location,
            isFlagged: isFlagged,
            isCompleted: false
        )
        tasks.append(newTask)
        sortTasks()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        completedTasks.removeAll { $0.id == id }
    }

    func updateTask(id: UUID, title: String, course: String, description: String, dueDate: Date, location: String?, isFlagged: Bool) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].title = title
            tasks[index].course = course
            tasks[index].description = description
            tasks[index].dueDate = dueDate
            tasks[index].location = location
            tasks[index].isFlagged = isFlagged
        }
    }

    func markTaskAsDone(task: remindModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.isCompleted = true
            completedTasks.append(updatedTask)
            tasks.remove(at: index)
            sortTasks()
        }
    }

    private func sortTasks() {
        tasks.sort()
        completedTasks.sort()
    }

    // event functions
    func addEvent(title: String, description: String, date: Date, location: String?, isFlagged: Bool, isAllDay: Bool, startDate: Date?, endDate: Date?) {
        let newEvent = eventModel(
            title: title,
            description: description,
            date: date,
            location: location,
            isFlagged: isFlagged,
            isAllDay: isAllDay,
            startDate: startDate,
            endDate: endDate
        )
        events.append(newEvent)
        sortEvents()
    }

    func updateEvent(id: UUID, title: String, description: String, date: Date, location: String?, isFlagged: Bool, isAllDay: Bool, startDate: Date?, endDate: Date?) {
        if let index = events.firstIndex(where: { $0.id == id }) {
            events[index].title = title
            events[index].description = description
            events[index].date = date
            events[index].location = location
            events[index].isFlagged = isFlagged
            events[index].isAllDay = isAllDay
            events[index].startDate = startDate
            events[index].endDate = endDate
            sortEvents()
        }
    }

    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
    }

    private func sortEvents() {
        events.sort()
    }

    func eventsForSelectedDate(_ selectedDate: Date) -> [eventModel] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? Date()

        return events.filter { event in
            let eventDate = event.date
            return eventDate >= dayStart && eventDate < dayEnd
        }
    }
}

