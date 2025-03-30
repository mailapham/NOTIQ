//
//  homeView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/28/25.
//

import SwiftUI

struct homeView: View {
    @ObservedObject var RemindInfo: remindInfo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("This is the home page")
                }
                .padding()
            }
            /*.navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)*/
        }
    }
}
