//
//  ContentView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var RemindInfo = remindInfo()
    
    var body: some View {
        TabView {
            remindView(RemindInfo: RemindInfo)
                .tabItem {
                    Label("TO-DO", systemImage: "list.bullet")
                }
            
           calendarView(RemindInfo: RemindInfo)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            mapView(RemindInfo: RemindInfo)
                .tabItem {
                    Label("Navigation", systemImage: "map")
                }
            settingView(RemindInfo: RemindInfo)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            setupAppearance()
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

#Preview {
    ContentView()
}
