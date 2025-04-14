//
//  ContentView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var remindInfoWrapper = RemindInfoLoader()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if let remindInfo = remindInfoWrapper.instance {
                VStack {
                    Text("NOTIQ")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                    Divider()
                        .padding(.horizontal, 20)

                    TabView {
                        homeView(RemindInfo: remindInfo)
                            .tabItem {
                                Label("Alerts", systemImage: "exclamationmark.bubble")
                            }

                        remindView(RemindInfo: remindInfo)
                            .tabItem {
                                Label("TO-DO", systemImage: "list.bullet")
                            }

                        calendarView(RemindInfo: remindInfo)
                            .tabItem {
                                Label("Calendar", systemImage: "calendar")
                            }

                        studyView(RemindInfo: remindInfo)
                            .tabItem {
                                Label("Study", systemImage: "book")
                            }
                    }
                    .onAppear {
                        setupAppearance()
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            if remindInfoWrapper.instance == nil {
                await remindInfoWrapper.load(using: modelContext)
            }
        }
    }
    
    // color of the navigation bar
    func setupAppearance() {
        // set navigation bar color
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(hex: "#3C5E95")
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            
        // set tab bar color
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(hex: "#3C5E95")
            
        // customize tab bar item appearance
        let itemAppearance = UITabBarItemAppearance()
            
        // set selected item color (icon and text)
        itemAppearance.selected.iconColor = UIColor(hex: "#FCD12A")
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "#FCD12A")]
            
        // set unselected item color (icon and text)
        itemAppearance.normal.iconColor = .white
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // apply the item appearance to all tab bar items
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// loads preadded data
@MainActor
class RemindInfoLoader: ObservableObject {
    @Published var instance: remindInfo?

    func load(using context: ModelContext) {
        let info = remindInfo(modelContext: context)
        info.loadData()
        self.instance = info
    }
}

#Preview {
    ContentView()
}
