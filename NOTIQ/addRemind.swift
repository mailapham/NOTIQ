//
//  addRemind.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/29/25.
//

import SwiftUI
import MapKit

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
    @State private var address: String? = ""
    @State private var hasLocation = false
    @State private var isFlagged = false
    
    @State private var locationQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isSearching = false
    
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
                    .onChange(of: hasLocation) { _, newValue in
                        if !newValue {
                            locationQuery = ""
                            searchResults = []
                            selectedMapItem = nil
                            location = ""
                        }
                    }

                    if hasLocation {
                        TextField("Search for a location", text: $locationQuery)
                            .onChange(of: locationQuery) { _, newValue in
                                searchLocations(query: newValue)
                            }

                        if let selected = selectedMapItem {
                             HStack {
                                Text("Selected: \(selected.name ?? "Unknown Location")")
                                Spacer()
                                Button {
                                    selectedMapItem = nil
                                    locationQuery = ""
                                    location = ""
                                    searchResults = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                             }
                        } else if isSearching {
                            ProgressView("Searching...")
                                .padding(.vertical)
                        } else if !searchResults.isEmpty {
                            List(searchResults, id: \.self) { item in
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown Name")
                                        .font(.headline)
                                    Text(item.placemark.title ?? "")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedMapItem = item
                                    location = item.name ?? "Unknown Location"
                                    locationQuery = item.name ?? ""
                                    address = item.placemark.title ?? "No address available"
                                    searchResults = []
                                }
                            }
                             .frame(maxHeight: 200)
                        } else if !locationQuery.isEmpty && !isSearching {
                             Text("No results found.")
                                .foregroundColor(.gray)
                                .padding(.vertical)
                        }
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
                    .disabled(title.isEmpty || course.isEmpty || (!hasDate && !hasTime) || (hasLocation && (address?.isEmpty ?? true)))
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
            address: hasLocation ? address : nil,
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
            address: hasLocation ? address : nil,
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
    
    private func searchLocations(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchResults = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            guard let response = response else {
                print("Error searching locations: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            searchResults = response.mapItems.filter { $0.name != nil && !$0.name!.isEmpty }
        }
    }
}
