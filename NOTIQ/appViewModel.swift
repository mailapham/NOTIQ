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
    @Published var studyPlaces: [studyModel] = []
    
    // creates a new task and adds it to the tasks array
    func addTask(title: String, course: String, description: String, dueDate: Date, location: String?, address: String?, isFlagged: Bool) {
        let newTask = remindModel(
            title: title,
            course: course,
            description: description,
            dueDate: dueDate,
            location: location,
            address: address,
            isFlagged: isFlagged,
            isCompleted: false
        )
        tasks.append(newTask)
        sortTasks()
    }
    
    // removes tasks from tasks and completedTasks by id
    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        completedTasks.removeAll { $0.id == id }
    }
    
    // updates an existing task if it exists in tasks or completedTasks
    func updateTask(id: UUID, title: String, course: String, description: String, dueDate: Date, location: String?, address: String?, isFlagged: Bool) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].title = title
            tasks[index].course = course
            tasks[index].description = description
            tasks[index].dueDate = dueDate
            tasks[index].location = location
            tasks[index].address = address
            tasks[index].isFlagged = isFlagged
            sortTasks()
        }
        else if let index = completedTasks.firstIndex(where: { $0.id == id }) {
            completedTasks[index].title = title
            completedTasks[index].course = course
            completedTasks[index].description = description
            completedTasks[index].dueDate = dueDate
            completedTasks[index].location = location
            completedTasks[index].address = address
            completedTasks[index].isFlagged = isFlagged
            sortTasks()
        }
    }
    
    // moves a task to the completedTasks
    func markTaskAsDone(task: remindModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.isCompleted = true
            completedTasks.append(updatedTask)
            tasks.remove(at: index)
            sortTasks()
        }
    }
    
    // moves a tasks from completedTasks back to active tasks
    func markTaskAsUndone(task: remindModel) {
        if let index = completedTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = completedTasks[index]
            updatedTask.isCompleted = false
            tasks.append(updatedTask)
            completedTasks.remove(at: index)
            sortTasks()
        }
    }
    
    private func sortTasks() {
        tasks.sort()
        completedTasks.sort()
    }
    
    // creates a new event and adds it to the events array
    func addEvent(title: String, description: String, date: Date, location: String?, address: String?, isFlagged: Bool, isAllDay: Bool, startDate: Date?, endDate: Date?) {
        let newEvent = eventModel(
            title: title,
            description: description,
            date: date,
            location: location,
            address: address,
            isFlagged: isFlagged,
            isAllDay: isAllDay,
            startDate: startDate,
            endDate: endDate
        )
        events.append(newEvent)
        sortEvents()
    }

    
    // updates an existing event if it exists
    func updateEvent(id: UUID, title: String, description: String, date: Date, location: String?, address: String?, isFlagged: Bool, isAllDay: Bool, startDate: Date?, endDate: Date?) {
        if let index = events.firstIndex(where: { $0.id == id }) {
            events[index].title = title
            events[index].description = description
            events[index].date = date
            events[index].location = location
            events[index].address = address
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
    
    // filters events based on the selected date
    func eventsForSelectedDate(_ selectedDate: Date) -> [eventModel] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        return events.filter { event in
            // all-day events: check if the date matches
            if event.isAllDay {
                return calendar.isDate(event.date, inSameDayAs: selectedDate)
            }
            // specified date times: check if the event's time range overlaps with the selected day
            else if let startDate = event.startDate, let endDate = event.endDate {
                return startDate < dayEnd && endDate > dayStart
            }
            return calendar.isDate(event.date, inSameDayAs: selectedDate)
        }
    }
    
    // filters tasks based on the selected date
    func tasksForSelectedDate(_ selectedDate: Date) -> [remindModel] {
        let calendar = Calendar.current
        let allTasks = tasks + completedTasks
        return allTasks.filter { calendar.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }
    
    // JSON web API call
    func fetchStudyPlaces() {
        let urlString = "https://secure.geonames.org/searchJSON?q=library&country=US&adminCode1=AZ&startRow=2&maxRows=12&username=mnpham5"
        
        guard let url = URL(string: urlString) else {
            return
        }
    
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received JSON: \(jsonString)")
            }
            
            do {
                let result = try JSONDecoder().decode(GeoNamesResponse.self, from: data)
                DispatchQueue.main.async {
                    print("Decoded \(result.geonames.count) study places")
                    self.studyPlaces = result.geonames
                }
            } catch {
                print("Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: \(type), path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: \(type), path: \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("Key not found: \(key), path: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
            }
        }.resume()
    }
    
    // creates a new studyPlace and adds it to the array
    func addStudyPlace(name: String, type: String, state: String, country: String, latitude: Double, longitude: Double) {
        let newStudyPlace = studyModel(
            name: name,
            type: type,
            state: state,
            country: country,
            latitude: latitude,
            longitude: longitude
        )
        studyPlaces.append(newStudyPlace)
    }

    // removes studyPlace by id
    func deleteStudyPlace(id: UUID) {
        studyPlaces.removeAll { $0.id == id }
    }
}
