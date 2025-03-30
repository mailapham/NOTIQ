//
//  addRemind.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/29/25.
//

import SwiftUI

struct addRemind: View {
    @ObservedObject var RemindInfo: remindInfo
    @Environment(\.dismiss) var dismiss
    var taskToEdit: remindModel?
    
    @State private var title = ""
    @State private var course = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var hasDate = false
    @State private var hasTime = false
    @State private var location = ""
    @State private var hasLocation = false
    @State private var isFlagged = false
    
    @FocusState private var isDatePickerActive: Bool
    @FocusState private var isTimePickerActive: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Course", text: $course)
                    TextField("Description", text: $description)
                }
                
                Section {
                    Toggle(isOn: $hasDate) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.red)
                            Text("Date")
                            Spacer()
                            if hasDate {
                                Text(formattedDate())
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if hasDate {
                        DatePicker("", selection: $dueDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .focused($isDatePickerActive)
                    }
                    
                    Toggle(isOn: $hasTime) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("Time")
                            Spacer()
                            if hasTime {
                                Text(formattedTime())
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                                        
                    if hasTime {
                        VStack {
                            DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .focused($isTimePickerActive)
                        }
                    }
                }
                
                Section {
                    Toggle(isOn: $hasLocation) {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.blue)
                            Text("Location")
                        }
                    }
                    
                    if hasLocation {
                        TextField("Enter Location", text: $location)
                    }
                }
                
                Section {
                    Toggle(isOn: $isFlagged) {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.red)
                            Text("Flag")
                        }
                    }
                }
            }
            .navigationTitle(taskToEdit == nil ? "Add Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(taskToEdit == nil ? "Add" : "Save") {
                        if let task = taskToEdit {
                            editTask(existingTask: task)
                        } else {
                            addTask()
                        }
                    }
                    .disabled(title.isEmpty || course.isEmpty || (!hasDate && !hasTime))
                }
            }
            .onAppear {
                if let task = taskToEdit {
                    title = task.title
                    course = task.course
                    description = task.description
                    dueDate = task.dueDate
                    hasDate = true
                    hasTime = true
                    location = task.location ?? ""
                    isFlagged = task.isFlagged
                }
            }
        }
    }
    
    private func addTask() {
        RemindInfo.addTask(
            title: title,
            course: course,
            description: description,
            dueDate: hasDate || hasTime ? dueDate : Date(),
            location: hasLocation ? location : nil,
            isFlagged: isFlagged
        )
        dismiss()
    }
    
    private func editTask(existingTask: remindModel) {
        RemindInfo.updateTask(
            id: existingTask.id,
            title: title,
            course: course,
            description: description,
            dueDate: hasDate || hasTime ? dueDate : Date(),
            location: hasLocation ? location : nil,
            isFlagged: isFlagged
        )
        dismiss()
    }
    
    private func formattedDate() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(dueDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: dueDate)
        }
    }
        
    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: dueDate)
    }
}
