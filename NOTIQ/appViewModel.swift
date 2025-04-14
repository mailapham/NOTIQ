//
//  appViewModel.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class remindInfo: ObservableObject {
    @Published var tasks: [remindModel] = []
    @Published var completedTasks: [remindModel] = []
    @Published var events: [eventModel] = []
    @Published var studyPlaces: [studyModel] = []
    
    private(set) var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // loadData()
    }
    
    // function loading pre-entered data
    func loadData() {
        do {
            // uncompleted tasks
            let tasksDescriptor = FetchDescriptor<remindModel>(
                predicate: #Predicate { $0.isCompleted == false }
            ) // doesn't contain sorting yet... fix
            
            tasks = try modelContext.fetch(tasksDescriptor)
            
            // completed tasks
            let completedTasksDescriptor = FetchDescriptor<remindModel>(
                predicate: #Predicate { $0.isCompleted == true }
            )
            
            completedTasks = try modelContext.fetch(completedTasksDescriptor)
            
            let eventDescriptor = FetchDescriptor<eventModel>()
            events = try modelContext.fetch(eventDescriptor)
            
            /*let studyPlaceDescriptor = FetchDescriptor<studyModel>()
             studyPlaces = try modelContext.fetch(studyPlaceDescriptor)*/
        } catch {
            print("Error loading data: \(error.localizedDescription)")
        }
    }
    
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
        modelContext.insert(newTask)
        saveAndReload()
    }
    
    // removes tasks from tasks and completedTasks by id
    func deleteTask(id: UUID) {
        do {
            try modelContext.delete(model: remindModel.self, where: #Predicate { $0.id == id })
            saveAndReload()
        } catch {
                print("Error deleting task: \(id): \(error.localizedDescription)")
        }
    }
    
    // updates an existing task if it exists in tasks or completedTasks
    func updateTask(id: UUID, title: String, course: String, description: String, dueDate: Date, location: String?, address: String?, isFlagged: Bool) {
        do {
            let descriptor = FetchDescriptor<remindModel>(predicate: #Predicate { $0.id == id })
            if let taskToUpdate = try modelContext.fetch(descriptor).first {
                taskToUpdate.title = title
                taskToUpdate.course = course
                taskToUpdate.descriptionText = description
                taskToUpdate.dueDate = dueDate
                taskToUpdate.location = location
                taskToUpdate.address = address
                taskToUpdate.isFlagged = isFlagged
                    
                saveAndReload()
                    
            } else {
                print("Error updating task: Task with ID \(id) not found.")
            }
        } catch {
            print("Error fetching task \(id) for update: \(error.localizedDescription)")
        }
    }
    
    // moves a task to the completedTasks
    func markTaskAsDone(task: remindModel) {
        guard !task.isCompleted else { return }
        task.isCompleted = true
        saveAndReload()
    }
    
    // moves a tasks from completedTasks back to active tasks
    func markTaskAsUndone(task: remindModel) {
        guard task.isCompleted else { return }
        task.isCompleted = false
        saveAndReload()
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
            startDate: isAllDay ? nil : startDate,
            endDate: isAllDay ? nil : endDate
        )
        modelContext.insert(newEvent)
        saveAndReload()
    }
                                    
    // updates an existing event if it exists
    func updateEvent(id: UUID, title: String, description: String, date: Date, location: String?, address: String?, isFlagged: Bool, isAllDay: Bool, startDate: Date?, endDate: Date?) {
        do {
            let descriptor = FetchDescriptor<eventModel>(predicate: #Predicate { $0.id == id })
            if let eventToUpdate = try modelContext.fetch(descriptor).first {
                eventToUpdate.title = title
                eventToUpdate.descriptionText = description // Check model property name
                eventToUpdate.date = date // Update the primary date field
                eventToUpdate.location = location
                eventToUpdate.address = address
                eventToUpdate.isFlagged = isFlagged
                eventToUpdate.isAllDay = isAllDay
                eventToUpdate.startDate = isAllDay ? nil : startDate
                eventToUpdate.endDate = isAllDay ? nil : endDate
                                                 
                saveAndReload()
            } else {
                print("Error updating event: Event with ID \(id) not found.")
            }
        } catch {
            print("Error fetching event \(id) for update: \(error.localizedDescription)")
        }
    }

    // removes event by id
    func deleteEvent(id: UUID) {
        do {
            try modelContext.delete(model: eventModel.self, where: #Predicate { $0.id == id })
            saveAndReload()
        } catch {
            print("Error deleting event \(id): \(error.localizedDescription)")
        }
    }
    
    // filters events based on the selected date
    func eventsForSelectedDate(_ selectedDate: Date) -> [eventModel] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }
        
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
      
    // save and reload data
    private func saveAndReload() {
        saveContext()
        loadData()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}
