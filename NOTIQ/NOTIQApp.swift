//
//  NOTIQApp.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI
import SwiftData

@main
struct NOTIQApp: App {
    let modelContainer: ModelContainer
    
    init () {
        do {
            let schema = Schema([
                remindModel.self,
                eventModel.self
                // studyModel.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Coun't create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
