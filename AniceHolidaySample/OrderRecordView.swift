//
//  OrderRecordView.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/8/8.
//

import SwiftUI

struct OrderRecordView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedItem: OrderItem?
    @State var orderRecord: CustomerOrder
    let recordId: String?

    var body: some View {

        VStack {
            ZStack {
                Rectangle()
                    .fill(Color.primary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding()

                VStack(alignment: .leading) {
                    Text(orderRecord.customerName)
                    Text(orderRecord.phoneNumber)
                    Text(orderRecord.address)
                    Text(orderRecord.orderDate)
                    Text(recordId ?? "no id")
                    Text(orderRecord.orderItems?.joined(separator: ", ") ?? "")
                }

            }

            Divider()

            Text("Purchaed Drink").font(.headline)

            if let items = orderRecord.itemsFromItems,
                let quantities = orderRecord.quantitiesFromItems,
                let sweetnesses = orderRecord.sweetnessesFromItems,
                let temperature = orderRecord.temperaturesFromItems,
                let topping = orderRecord.toppingsFromItems,
                let price = orderRecord.pricesFromItems,
                let itemIDs = orderRecord.orderItems
            {
                List {
                    ForEach(0..<items.count, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(items[index])
                                    .font(.title3)
                                Text(
                                    "\(temperature[index]), \(sweetnesses[index]), 加\(topping[index])"
                                )
                                .font(.subheadline)
                            }
                            Spacer()
                            Text("\(quantities[index]) 杯, $\(price[index])")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = OrderItem(
                                id: itemIDs[index],
                                orderId: orderRecord.id,
                                item: items[index],
                                quantity: quantities[index],
                                sweetness: sweetnesses[index],
                                temperature: temperature[index],
                                topping: topping[index],
                                price: price[index])

                            print(items[index])
                            print(itemIDs[index])
                        }
                    }

                }
            } else {
                Text("No drink information avaliable")
            }

        }
        .sheet(item: $selectedItem) { orderedItem in
            //                if let drink = dataManager.getDrink(for: orderedItem.item) {
            //                    ItemDetailView(orderItem: orderedItem, drink: drink)
            //                        .environmentObject(dataManager)
            //                } else {
            //                    Text("No drink information avaliable")
            //                }
            if let drink = dataManager.menuItems.first(where: {
                $0.fields.item == orderedItem.item
            }) {
                ItemDetailView(
                    drink: drink.fields,
                    orderItem: orderedItem,
                    mode: .editOrderItem,
                    orderRecordId: recordId
                    
                )
                .environmentObject(dataManager)
            } else {
                Text("No drink information available")
            }
        }
        .overlay {
            if dataManager.isUpdating {
                ZStack {
                    Color.white.opacity(0.6)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .offset(y: -100)
                }
            }
        }
        .onChange(of: dataManager.isUpdating) {
            if let updatedOrder = dataManager.purchasedList.first(where: {
                $0.fields.id == orderRecord.id
            }) {
                orderRecord = updatedOrder.fields
            }
        }
    }
}

#Preview {
    let sampleOrder = CustomerOrder(
        id: "sample_id",
        customerName: "天音かなた",
        phoneNumber: "0919123456",
        address: "台北市中正區重慶南路一段122號",
        totalAmount: 350,
        note: "少冰",
        orderDate: "2024-08-12 14:30",
        orderItems: ["item1", "item2"],
        pricesFromItems: [80, 70],
        toppingsFromItems: ["珍珠", "椰果"],
        temperaturesFromItems: ["少冰", "常溫"],
        sweetnessesFromItems: ["半糖", "微糖"],
        quantitiesFromItems: [1, 2],
        itemsFromItems: ["珍珠奶茶", "四季春茶"]
    )

    OrderRecordView(orderRecord: sampleOrder, recordId: "sample_id")
        .environmentObject(DataManager())

    //    OrderRecordView()
    //        .environmentObject(DataManager())
}
