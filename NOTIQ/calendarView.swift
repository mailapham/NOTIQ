//
//  calendarView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI

struct calendarView: View {
    @ObservedObject var RemindInfo: remindInfo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("This is for the calendar")
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
