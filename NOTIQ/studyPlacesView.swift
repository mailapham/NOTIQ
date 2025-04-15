//
//  studyPlacesView.swift
//  NOTIQ
//
//  Created by Maila Pham on 4/13/25.
//

import SwiftUI
import MapKit

struct studyPlaceView: View {
    let studyPlace: studyModel
    @State private var region: MKCoordinateRegion
    
    init(studyPlace: studyModel) {
        self.studyPlace = studyPlace
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: studyPlace.latitude, longitude: studyPlace.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        ))
    }

    var body: some View {
        VStack {
            Map(coordinateRegion: $region, annotationItems: [studyPlace]) { place in
                MapPin(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), tint: Color(hex: "722F9C").opacity(0.3))
            }
            .onAppear {
                self.region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: studyPlace.latitude, longitude: studyPlace.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                )
            }
            .padding()
            .border(Color.gray, width: 1)
        }
        //.background(Color(hex: "#E4EAF0"))
        .navigationTitle(studyPlace.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
