//
//  ItemDetailView.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/6/28.
//

import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    var drink: Drink
    @State var orderItem: OrderItem?
    let mode: ItemDetailMode
    let orderRecordId: String?

    @State private var tempSelectedIndex: Int = 0
    @State private var sweetSelectedIndex: Int = 0
    @State private var selectedTopping: String = "不加料"
    @State private var quantity: Int = 1

    let temperatureRoles = ["熱", "正常冰", "少冰", "微冰", "去冰", "完全去冰"]
    let sweetnessRoles = ["正常甜", "七分甜", "五分甜", "三分甜", "一分甜", "無糖"]
    let toppings: [String: Int] = [
        "不加料": 0,
        "琥珀粉圓": 10,
        "嫩仙草": 10,
        "粉粿": 10,
        "雙粉": 10,
        "草仔粿": 10,
    ]

    enum ItemDetailMode {
        case newItem
        case editCartItem
        case editOrderItem
    }

    init(drink: Drink, orderItem: OrderItem? = nil, mode: ItemDetailMode, orderRecordId: String? = nil) {
        self.drink = drink
        self.mode = mode
        self.orderRecordId = orderRecordId

        switch mode {
        case .newItem:
            _orderItem = State(initialValue: nil)
        case .editCartItem, .editOrderItem:
            _orderItem = State(initialValue: orderItem)
            if let item = orderItem {
                _tempSelectedIndex = State(
                    initialValue: temperatureRoles.firstIndex(of: item.temperature) ?? 0)
                _sweetSelectedIndex = State(
                    initialValue:
                        sweetnessRoles.firstIndex(of: item.sweetness) ?? 0)
                _selectedTopping = State(
                    initialValue:
                        item.topping ?? "不加料")
                _quantity = State(initialValue: item.quantity)
            }
        }
    }

    var totalPrice: Int {
        let basePrice = drink.price
        let toppingPrice = toppings[selectedTopping]
        return (basePrice + toppingPrice!) * quantity
    }

    var body: some View {
        ZStack {
            Image("background01")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .ignoresSafeArea()

            ZStack {
                Rectangle()
                    .fill(Color.primary.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding()

                VStack {
                    Text(drink.item)
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()

                    Text(drink.description)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    Picker(selection: $tempSelectedIndex) {
                        ForEach(temperatureRoles.indices, id: \.self) { index in
                            Text(temperatureRoles[index])
                        }
                    } label: {
                        Text("temperature")
                    }
                    .pickerStyle(.segmented)
                    .padding(5)

                    Picker(selection: $sweetSelectedIndex) {
                        ForEach(sweetnessRoles.indices, id: \.self) { index in
                            Text(sweetnessRoles[index])
                        }
                    } label: {
                        Text("sweetness")
                    }
                    .pickerStyle(.segmented)
                    .padding(5)

                    Text("Topping")
                        .font(.title2)
                        .foregroundStyle(.white)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10
                    ) {
                        ForEach(toppings.keys.sorted(), id: \.self) { topping in
                            Button(action: {
                                selectedTopping = topping
                            }) {
                                VStack {
                                    Text(topping)
                                    Text("$\(toppings[topping]!)")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(selectedTopping == topping ? Color.white : Color.clear)
                                .foregroundStyle(selectedTopping == topping ? .black : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()

                    VStack {
                        Text("Quantity")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(5)

                        HStack {
                            Button(action: {
                                if quantity > 1 {
                                    quantity -= 1
                                }
                            }) {
                                Image(systemName: "minus")
                                    .foregroundStyle(.white)
                                    .frame(width: 25, height: 25)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }

                            Text("\(quantity)")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(minWidth: 25)

                            Button(action: {
                                quantity += 1
                            }) {
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                                    .frame(width: 25, height: 25)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }

                        Button(
                            action: {
                                updateDrink()
                                dismiss()
                            },
                            label: {
                                Text(buttonLabel)
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.clear)
                                    .foregroundStyle(Color.white)
                                    .padding()
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white, lineWidth: 1.5)
                                    }
                            }
                        )
                        .padding()
                    }
                }
                .padding()
            }
        }
    }

    var buttonLabel: String {
        switch mode {
        case .newItem:
            return "Add \(quantity) to Cart: $\(totalPrice)"
        case .editCartItem:
            return "Update: $\(totalPrice)"
        case .editOrderItem:
            return "Update: $\(totalPrice)"
        }
    }

    func updateDrink() {
        let updatedDrink = OrderItem(
            id: orderItem?.id,
            orderId: orderItem?.orderId,
            customerName: orderItem?.customerName,
            item: drink.item,
            quantity: quantity,
            sweetness: sweetnessRoles[sweetSelectedIndex],
            temperature: temperatureRoles[tempSelectedIndex],
            topping: selectedTopping,
            price: totalPrice
        )

        switch mode {
        case .newItem:
            dataManager.addToCart(
                drink: drink,
                sweetness: sweetnessRoles[sweetSelectedIndex],
                temperature: temperatureRoles[tempSelectedIndex],
                topping: selectedTopping,
                quantity: quantity,
                totalPrice: totalPrice)
            print("新項目已添加到購物車")
        case .editCartItem:
            dataManager.upadteCartItam(updateItem: updatedDrink)
            print("購物車項目已更新")
        case .editOrderItem:
            if let itemId = orderItem?.id {
                
                let updateField = OrderItemUpdate(
                    item: updatedDrink.item,
                    quantity: updatedDrink.quantity,
                    sweetness: updatedDrink.sweetness,
                    temperature: updatedDrink.temperature,
                    topping: updatedDrink.topping,
                    price: updatedDrink.price
                )

                let updateRequest = updateRequest(fields: updateField)

                dataManager.isUpdating = true
                dataManager.updateOrderItem(itemId: itemId, data: updateRequest) { result in
                    switch result {
                    case .success(let response):
                        print("Order items 修改成功 \(response)")
                        DispatchQueue.main.async {
                            dataManager.modifyPurchasedList(orderId: orderRecordId!, updatedItem: updatedDrink)
                            
                            if let updatedOrder = self.dataManager.purchasedList.first(where: { $0.id == orderRecordId }) {
                                let newTotalAmount = updatedOrder.fields.totalAmount
                                
                                // 更新 Airtable 中的訂單總金額
                                dataManager.updateOrderTotal(orderId: orderRecordId!, newTotalAmount: newTotalAmount) { result in
                                    switch result {
                                    case .success():
                                        print("訂單總金額更新成功，新總金額: \(newTotalAmount)")
                                    case .failure(let error):
                                        print("訂單總金額更新錯誤: \(error)")
                                    }
                                }
                            } else {
                                print("找不到要更新的訂單，orderId: \(orderRecordId!)")
                                print("可用的訂單 ID:")
                                self.dataManager.purchasedList.forEach { order in
                                    print("ID: \(String(describing: order.id)), Fields ID: \(order.fields.id ?? "N/A")")
                                }
                            }
                            
                            dataManager.isUpdating = false
                        }
                    case .failure(let error):
                        print("Airtable 更新錯誤: \(error)")
                        DispatchQueue.main.async {
                            dataManager.isUpdating = false
                        }
                    }
                }
            } else {
                print("無法更新 Airtable：缺少項目 ID 或訂單 ID")
                print("orderItem: \(String(describing: orderItem))")
            }
        }
    }
}

struct ItemDetailModeProvider: PreviewProvider {
    static var previews: some View {
        let sampleDrink = Drink(
            item: "竹香翡翠",
            quantity: 1,
            categories: "Sample Category",
            description:
                "茶香中帶有淡淡竹子香氣。大杯總糖量40.5克，總熱量177.5大卡。咖啡因總含量低於100毫克，每日攝取限量 300 毫克, 孩童及孕哺婦斟酌食用。 糖量、熱量及咖啡因含量皆以最高值標示。 茶葉產地台灣。",
            price: 40
        )

        let sampleOrderItem = OrderItem(
            id: "sample_id",
            orderId: "sample_order_id",
            customerName: "測試顧客",
            item: "竹香翡翠",
            quantity: 1,
            sweetness: "正常甜",
            temperature: "正常冰",
            topping: "不加料",
            price: 40
        )

        // 使用 ForEach 來為每個模式創建一個預覽。
        return ForEach(modes, id: \.self) { mode in
            ItemDetailView(drink: sampleDrink, orderItem: sampleOrderItem, mode: mode)
                .environmentObject(DataManager())
                .previewDisplayName(mode.description)
        }
    }

    static var modes: [ItemDetailView.ItemDetailMode] {
        [.newItem, .editCartItem, .editOrderItem]
    }
}
extension ItemDetailView.ItemDetailMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .newItem:
            return "加入新飲料"
        case .editCartItem:
            return "編輯購物車項目"
        case .editOrderItem:
            return "編輯訂單項目"
        }
    }
}

#Preview {
    ItemDetailModeProvider.previews
}
