//
//  ContentView.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/6/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    
    @State var selectedTab = Tab.menu
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    tab.view(editMode: $editMode)
                        .tabItem {
                        Label(tab.label, systemImage: tab.icon)
                    }
                    .badge(tab.badge(dataManager: dataManager))
                    .tag(tab)
                }
            }
            .navigationTitle(selectedTab.label)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedTab == .cart {
                        EditButton()
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .environmentObject(dataManager)
    }
}




#Preview {
    ContentView()
}
