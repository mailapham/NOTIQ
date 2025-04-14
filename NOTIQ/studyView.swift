//
//  studyView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI
import MapKit

struct studyView: View {
    @ObservedObject var RemindInfo: remindInfo
    @State private var isLoading = true
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if isLoading {
                        ProgressView("Loading study places...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if RemindInfo.studyPlaces.isEmpty {
                        Text("No study places found. Tap + to add a new study place.")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(RemindInfo.studyPlaces) { study in
                            NavigationLink(destination: studyPlaceView(studyPlace: study)) {
                                VStack(alignment: .leading) {
                                    Text(study.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Text(study.type)
                                        .font(.subheadline)
                                    Text("\(study.state), \(study.country)")
                                        .font(.caption)
                                }
                            }
                        }
                        .onDelete(perform: deleteStudyPlaces)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "#3C5E95"))
                                .padding(.vertical)
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            .sheet(isPresented: $showingAddSheet) {
                addStudyPlace(RemindInfo: RemindInfo)
            }
            .onAppear {
                isLoading = true
                RemindInfo.fetchStudyPlaces()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }
        }
    }

    func deleteStudyPlaces(at offsets: IndexSet) {
        let indicesToDelete = offsets.map { $0 }

        for index in indicesToDelete.sorted(by: >) {
            if index < RemindInfo.studyPlaces.count {
                let studyPlaceToDelete = RemindInfo.studyPlaces[index]
                RemindInfo.deleteStudyPlace(id: studyPlaceToDelete.id)
            }
        }
    }
}
