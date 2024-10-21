//
//  MenuView.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/7/4.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedDrink: Drink?
    
    @State private var selectedCategory:String = ""
    
    var items: [CategoryGroup] {
        dataManager.groupedItems
    }
    
    var body: some View {

        List (items) { category in
            Section {
                ForEach(category.records.map(\.fields)) { drink in
                    VStack (alignment: .leading) {
                        HStack {
                            Text(drink.item)
                            Spacer()
                            Text("Price: \(drink.price)")
                        }
                        Text(drink.description)
                    }
                    .onTapGesture {
                        selectedDrink = drink
                    }
                    
                }
            } header: {
                Text(category.id)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear(perform: {
            guard dataManager.menuItems.isEmpty else { return }
            dataManager.fetchTableData(tableName: "Menu") { (response: ResponseData) in
                dataManager.menuItems = response.records
            }
            
            
        })
        .sheet(item: $selectedDrink) { drink in
            ItemDetailView(drink: drink, mode: .newItem)
                .environmentObject(dataManager)
        }
        
    }
    
}

#Preview {
    MenuView()
        .environmentObject(DataManager())
}
