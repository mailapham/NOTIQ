//
//  mapView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI

struct mapView: View {
    @ObservedObject var RemindInfo: remindInfo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("This page is for the map")
                }
                .padding()
            }
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

