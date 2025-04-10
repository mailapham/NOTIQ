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
    @State private var endDate = Date().addingTimeInterval(3600)

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
                    .onChange(of: isAllDay) { _, newValue in
                        // switching to an all-day event
                        if newValue {
                            let calendar = Calendar.current
                            startDate = calendar.startOfDay(for: startDate)
                            endDate = calendar.startOfDay(for: startDate)
                        // switching to a specific timed event
                        } else {
                            endDate = startDate.addingTimeInterval(3600)
                        }
                    }

                    // all-day event: showing date picker without the time displayed
                    if isAllDay {
                        DatePicker("Event Date", selection: $startDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .focused($isDatePickerActive)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .onChange(of: startDate) { _, newValue in
                                endDate = newValue
                            }
                    // specified time event: show start/end date pickers
                    } else {
                        HStack {
                            Text("Starts")
                            DatePicker("Start Date and Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .focused($isStartTimePickerActive)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .onChange(of: startDate) { _, newValue in
                                    // ensure end date is always after start date
                                    if endDate <= newValue {
                                        endDate = newValue.addingTimeInterval(3600)
                                    }
                                }
                        }

                        HStack {
                            Text("Ends")
                            DatePicker("End Date and Time", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .focused($isEndTimePickerActive)
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
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                // editing an existing event, populate current fields
                if let event = eventToEdit {
                    title = event.title
                    description = event.description
                    location = event.location ?? ""
                    isFlagged = event.isFlagged
                    isAllDay = event.isAllDay
                    
                    if isAllDay {
                        startDate = event.date
                        endDate = event.date
                    } else {
                        startDate = event.startDate ?? event.date
                        endDate = event.endDate ?? event.date.addingTimeInterval(3600)
                    }
                    
                    hasLocation = event.location != nil
                }
            }
        }
    }

    private func addEvent() {
        RemindInfo.addEvent(
            title: title,
            description: description,
            date: isAllDay ? startDate : startDate,
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
            date: isAllDay ? startDate : startDate,
            location: hasLocation ? location : nil,
            isFlagged: isFlagged,
            isAllDay: isAllDay,
            startDate: isAllDay ? nil : startDate,
            endDate: isAllDay ? nil : endDate
        )
        dismiss()
    }
}
