//
//  CartView.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/7/2.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedItems = Set<String>()
    @Binding var editMode: EditMode

    @State private var editDrink: OrderItem?

    @State var showCheckoutView = false
    
    @State var isLoading: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if editMode.isEditing {
                    editListView
                } else {
                    normalListView
                }
            }

            VStack {
                Divider()
                bottomButton
                    .sheet(
                        isPresented: $showCheckoutView,
                        content: {
                            CheckoutView(isLoading: $isLoading)
                        })
            }
            .padding()

        }
        .environment(\.editMode, $editMode)
        .overlay {
            if isLoading {
                ZStack {
                    Color.white.opacity(0.6)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            }
        }
        .sheet(
            item: $editDrink,
            content: { orderItem in
                if let drink = dataManager.menuItems.first(where: {
                    $0.fields.item == orderItem.item
                }) {
                    ItemDetailView(drink: drink.fields, orderItem: orderItem, mode: .editCartItem)
                        .environmentObject(dataManager)
                } else {
                    Text("Drink not found")
                        .onAppear {
                            print("Failed to find drink for item: \(orderItem.item)")
                            print(
                                "Available menu items: \(dataManager.menuItems.map { $0.fields.item })"
                            )
                        }
                }

            }
        )
        .onReceive(dataManager.objectWillChange) { _ in
            isLoading = true
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }

    func cartItemView(item: OrderItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(item.item)
                    .font(.title3)
                Text("\(item.temperature), \(item.sweetness)")
                    .font(.subheadline)
            }
            Spacer()
            Text("\(item.quantity) 杯, $\(item.price)")
        }
        .tag(item.id ?? "")
    }

    var editListView: some View {
        List(selection: $selectedItems) {
            ForEach(dataManager.cartItems) { item in
                cartItemView(item: item)
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
        }
    }

    var normalListView: some View {
        List {
            ForEach(dataManager.cartItems) { item in
                cartItemView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Tapped item: \(item.item)")
                        editDrink = item
                    }
            }
        }
    }

    var bottomButton: some View {
        if editMode.isEditing {
            customBarBtn(
                title: "Delete",
                action:
                    deleteSelectedItems, isDisabled: selectedItems.isEmpty, activeColor: .red)
        } else {
            customBarBtn(
                title: "Checkout: $\(dataManager.totalAmount())",
                action: {
                    showCheckoutView.toggle()
                }, isDisabled: dataManager.cartItems.isEmpty, activeColor: .blue)
        }
    }

    func deleteItems(at offsets: IndexSet) {
        dataManager.cartItems.remove(atOffsets: offsets)
    }

    func moveItems(form source: IndexSet, to destination: Int) {
        dataManager.cartItems.move(fromOffsets: source, toOffset: destination)
    }

    func deleteSelectedItems() {
        withAnimation(.easeOut) {
            dataManager.cartItems.removeAll { item in
                selectedItems.contains(item.id ?? "")
            }
            selectedItems.removeAll()
        }
    }

}

struct customBarBtn: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    let activeColor: Color
    let disabledColor = Color.gray.opacity(0.5)

    var body: some View {
        Button(
            action: action,
            label: {
                Text(title)
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(isDisabled ? disabledColor : .white)
                    .padding()
                    .background(isDisabled ? disabledColor : activeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        )
        .disabled(isDisabled)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var editMode: EditMode = .inactive
        var body: some View {
            let dataManager = DataManager()
            dataManager.cartItems = [
                OrderItem(
                    id: UUID().uuidString, customerName: "Alice", item: "奶蓋招牌紅茶", quantity: 1,
                    sweetness: "一分甜", temperature: "少冰", topping: "粉粿", price: 50),
                OrderItem(
                    id: UUID().uuidString, customerName: "Bob", item: "招牌冬瓜紅", quantity: 2,
                    sweetness: "三分甜", temperature: "微冰", topping: "不加料", price: 80),
            ]
            return NavigationStack {
                CartView(editMode: $editMode)
                    .environmentObject(dataManager)
            }
        }
    }
    return PreviewWrapper()

}
