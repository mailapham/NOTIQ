//
//  remindView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI

struct remindView: View {
    @ObservedObject var RemindInfo: remindInfo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("This page is for the remind/TO-DO list")
                }
                .padding()
            }
            .navigationTitle("TO-DO")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
