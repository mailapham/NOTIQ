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
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    Text("Your Study Places")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isLoading {
                        ProgressView("Loading study places...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else if RemindInfo.studyPlaces.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                                .frame(height: 175)
                            
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Study Places Saved")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("Tap '+' to add a new study place")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List {
                            ForEach(RemindInfo.studyPlaces) { study in
                                NavigationLink(destination: studyPlaceView(studyPlace: study)) {
                                    studyPlaceCard(study: study)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteStudyPlaces)
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                HStack {
                     Spacer()
                     Button(action: {
                         showingAddSheet = true
                     }) {
                         Image(systemName: "plus.circle.fill")
                             .font(.system(size: 50))
                             .foregroundColor(Color(hex: "#3C5E95"))
                             .padding(.trailing)
                             .padding(.bottom)
                     }
                }
            }
            .navigationBarHidden(true)
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

    @ViewBuilder
    private func studyPlaceCard(study: studyModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(study.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(study.type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("\(study.state), \(study.country)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 10)

            Spacer()

        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
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
