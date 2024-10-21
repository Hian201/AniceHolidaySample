//
//  Tab.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/7/8.
//

import Foundation
import SwiftUI

enum Tab: Int, Identifiable, CaseIterable {
    var id: Int {
        self.rawValue
    }
    
    case menu, cart, history
    
    var label: String {
        switch self {
        case .menu: "Menu"
        case .cart: "Cart"
        case .history: "History"
        }
    }
    
    var icon: String {
        switch self {
        case .menu:
            "list.bullet"
        case .cart:
            "cart"
        case .history:
            "clock"
        }
    }
    
    
    @ViewBuilder
    func view(editMode: Binding<EditMode>) -> some View {
        switch self {
        case .menu:
            MenuView()
            
        case .cart:
            CartView(editMode: editMode)
            
        case .history:
            OrderHistoryView()
        }
    }
//    var view: some View {
//        switch self {
//        case .menu:
//            MenuView()
//            
//        case .cart:
//            CartView()
//        }
//    }
    
    
    func badge(dataManager: DataManager) -> Int {
        switch self {
        case .menu: 
            return 0
        case .cart:
            return dataManager.totalQuantity()
        case .history:
            return 0
        }
    }
}
