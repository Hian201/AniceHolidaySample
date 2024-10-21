//
//  OrderHistoryView.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/8/5.
//

import SwiftUI

struct OrderHistoryView: View {
    @EnvironmentObject var dataManager: DataManager

    var historyOrder: [CustomerOrderRecord] {
        dataManager.purchasedList
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(dataManager.purchasedList) { record in
                    NavigationLink(destination: OrderRecordView(orderRecord: record.fields, recordId: record.id)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.fields.customerName)
                                    .font(.title3)
                                Text(record.fields.orderDate)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            Text("$\(record.fields.totalAmount)")
                        }
                    }
                }
                .onDelete(perform: deleteFromList)
            }
        }
        .onAppear(perform: {
            dataManager.fetchTableData(tableName: "Order") { (response: CustomerOrderResponse) in
                dataManager.purchasedList = dataManager.orderHistorySort(
                    orderData: response.records)
                //                print(historyOrder)
            }
        })
    }
    
    func deleteFromList(at offsets: IndexSet) {
        dataManager.deleteOrder(at: offsets)
    }
}

#Preview {
    OrderHistoryView().environmentObject(DataManager())
}
