//
//  addStudyPlace.swift
//  NOTIQ
//
//  Created by Maila Pham on 4/13/25.
//

import SwiftUI
import MapKit

struct addStudyPlace: View {

    @ObservedObject var RemindInfo: remindInfo
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var state = ""
    @State private var country = ""
    @State private var type = ""
    @State private var customType = ""
    @State private var locationQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isSearching = false

    let studyTypes = ["library", "cafe", "park", "university", "bookstore", "other"]

    var isSaveDisabled: Bool {
        selectedMapItem == nil || type.isEmpty || (type == "Other" && customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Location") {
                    TextField("Search for location", text: $locationQuery)
                        .onChange(of: locationQuery) { _, newValue in
                            if selectedMapItem?.name != newValue {
                                selectedMapItem = nil
                            }
                            searchLocations(query: newValue)
                        }

                    if let selected = selectedMapItem {
                         HStack {
                            VStack(alignment: .leading) {
                                Text("Selected: \(selected.name ?? "Unknown")")
                                Text(selected.placemark.title ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button {
                                selectedMapItem = nil
                                locationQuery = ""
                                name = ""
                                state = ""
                                country = ""
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
                                name = item.name ?? ""
                                state = item.placemark.administrativeArea ?? ""
                                country = item.placemark.country ?? ""
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

                Section("Details") {
                    TextField("Name", text: $name)
                        .disabled(selectedMapItem == nil)

                    Picker("Type", selection: $type) {
                        Text("Select Type").tag("")
                        ForEach(studyTypes, id: \.self) { studyType in
                            Text(studyType).tag(studyType)
                        }
                    }
                     .disabled(selectedMapItem == nil)

                    if type == "Other" {
                        TextField("Enter custom type", text: $customType)
                            .disabled(selectedMapItem == nil)
                    }

                    TextField("State/Province", text: $state)
                        .disabled(selectedMapItem == nil)
                    TextField("Country", text: $country)
                        .disabled(selectedMapItem == nil)
                }
            }
            .navigationTitle("Add Study Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveStudyPlace()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    func saveStudyPlace() {
        guard let selectedPlace = selectedMapItem else {
            print("Error: No location selected.")
            return
        }

        let finalType: String
        if type == "Other" {
            let trimmedCustomType = customType.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedCustomType.isEmpty else {
                 print("Error: Custom type not submitted.")
                 return
             }
            finalType = trimmedCustomType
        } else {
            finalType = type
        }

        let latitude = selectedPlace.placemark.coordinate.latitude
        let longitude = selectedPlace.placemark.coordinate.longitude

        RemindInfo.addStudyPlace(
            name: name,
            type: finalType,
            state: state,
            country: country,
            latitude: latitude,
            longitude: longitude
        )
        presentationMode.wrappedValue.dismiss()
    }

    private func searchLocations(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        if let selectedName = selectedMapItem?.name, query == selectedName {
            isSearching = false
            searchResults = []
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
                self.searchResults = []
                return
            }

            self.searchResults = response.mapItems.filter { item in
                guard let name = item.name, !name.isEmpty else { return false }
                let coordinate = item.placemark.coordinate
                return coordinate.latitude != 0 || coordinate.longitude != 0
            }
        }
    }
}
