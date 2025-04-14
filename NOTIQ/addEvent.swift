//
//  addEvent.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/29/25.
//

import SwiftUI
import MapKit

struct addEvent: View {
    @ObservedObject var RemindInfo: remindInfo
    @Environment(\.dismiss) var dismiss
    var eventToEdit: eventModel?

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var address: String? = ""
    @State private var hasLocation = false
    @State private var isFlagged = false
    @State private var isAllDay = false
    
    @State private var locationQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isSearching = false

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
                                    address = item.placemark.title ?? nil 
                                    locationQuery = item.name ?? ""
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
                    .disabled(title.isEmpty || (hasLocation && (address?.isEmpty ?? true)))
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
            address: hasLocation ? address : nil,
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
            address: hasLocation ? address : nil,
            isFlagged: isFlagged,
            isAllDay: isAllDay,
            startDate: isAllDay ? nil : startDate,
            endDate: isAllDay ? nil : endDate
        )
        dismiss()
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
