//
//  addEvent.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/29/25.
//

import SwiftUI

struct addEvent: View {
    @ObservedObject var RemindInfo: remindInfo
    @Environment(\.dismiss) var dismiss
    var eventToEdit: eventModel?

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var hasLocation = false
    @State private var isFlagged = false
    @State private var isAllDay = false

    @State private var startDate = Date()
    @State private var endDate = Date()

    @FocusState private var isDatePickerActive: Bool
    @FocusState private var isStartTimePickerActive: Bool
    @FocusState private var isEndTimePickerActive: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    TextField("Description", text: $description)
                }

                Section {
                    Toggle(isOn: $isAllDay) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.yellow)
                            Text("All Day")
                        }
                    }

                    if isAllDay {
                        DatePicker("Event Date", selection: $startDate, displayedComponents: [.date])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .focused($isDatePickerActive)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        HStack {
                            Text("Starts")
                            DatePicker("Start Date and Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .focused($isStartTimePickerActive)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        HStack {
                            Text("Ends")
                            DatePicker("End Date and Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .focused($isEndTimePickerActive)
                                .disabled(startDate >= endDate && startDate != endDate) // Prevent end date from being before start date
                                .frame(maxWidth: .infinity, alignment: .trailing)
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
            .navigationTitle(eventToEdit == nil ? "Add Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(eventToEdit == nil ? "Add" : "Save") {
                        if let event = eventToEdit {
                            editEvent(existingEvent: event)
                        } else {
                            addEvent()
                        }
                    }
                    .disabled(title.isEmpty || startDate == Date())
                }
            }
            .onAppear {
                if let event = eventToEdit {
                    title = event.title
                    description = event.description
                    location = event.location ?? ""
                    isFlagged = event.isFlagged
                    startDate = event.startDate ?? event.date
                    endDate = event.endDate ?? event.date
                    isAllDay = startDate == endDate
                    hasLocation = event.location != nil
                }
            }
            .task {
                // all-day toggle logic
                if startDate == endDate {
                    isAllDay = true
                } else {
                    isAllDay = false
                }
            }
        }
    }

    private func addEvent() {
        RemindInfo.addEvent(
            title: title,
            description: description,
            date: startDate, // default for all-day
            location: hasLocation ? location : nil,
            isFlagged: isFlagged,
            isAllDay: isAllDay,
            startDate: isAllDay ? nil : startDate,
            endDate: isAllDay ? nil : endDate
        )
        dismiss()
    }

    private func editEvent(existingEvent: eventModel) {
        RemindInfo.updateEvent(
            id: existingEvent.id,
            title: title,
            description: description,
            date: startDate,
            location: hasLocation ? location : nil,
            isFlagged: isFlagged,
            isAllDay: isAllDay,
            startDate: isAllDay ? nil : startDate,
            endDate: isAllDay ? nil : endDate
        )
        dismiss()
    }
}
