//
//  CheckoutView.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/7/19.
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var customer = ""
    @State private var phoneNum = ""
    @State private var address = ""
    @State private var note = ""
    
    @Environment(\.dismiss) var dismiss
    @Binding var isLoading: Bool
    
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let outerPadding = geometry.size.width * 0.05
                let innerPadding = geometry.size.width * 0.03
                
                Rectangle()
                    .fill(Color.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding(outerPadding)
                
                VStack {
                    Text("Checkout")
                        .font(.title)
                        .padding()
                    
                    VStack {
                        TextField("Your name", text: $customer)
                            .frame(width: 250, height: 20)
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.primary, lineWidth: 1)
                            }
                            .padding()
                        
                        TextField("Phone", text: $phoneNum)
                            .frame(width: 250, height: 20)
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.primary, lineWidth: 1)
                            }
                            .padding()
                        
                        TextField("Address", text: $address)
                            .frame(width: 250, height: 20)
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.primary, lineWidth: 1)
                            }
                            .padding()
                        
                        TextField("Note", text: $note)
                            .frame(width: 250, height: 40)
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.primary, lineWidth: 1)
                            }
                            .padding()
                    }
                    
                    Spacer()
                    customBarBtn(title: "Payment: $\(dataManager.totalAmount())", action: {
                        payment()
                        dismiss()
                    }, isDisabled: customer.isEmpty, activeColor: .blue)
                    .padding(innerPadding)
                }
                .padding(outerPadding + innerPadding)
                .frame(width: geometry.size.width, height: geometry.size.height)
                
            }
        }
    }
    
    func payment() {
//        let orderData = dataManager.createOrderRecords(customer: customer, phoneNum: phoneNum, address: address, note: note, amount: dataManager.totalAmount())
//        dataManager.uploadOrder(createdRecords: orderData, customerName: customer)
        
        isLoading = true
        DispatchQueue.main.async {
            dataManager.uploadOrderAndItems(customerName: customer, phoneNum: phoneNum, address: address, note: note)
        }
    }
}

#Preview {
    CheckoutView(isLoading: .constant(false)).environmentObject(DataManager())
    
//    let sampleOrder = CustomerOrder(customerName: "Fiber", phoneNumber: 0912345678, address: "重慶南路一段122號", totalAmount: 100)
//    
//    return CheckoutView(order: sampleOrder).environmentObject(DataManager())
}
