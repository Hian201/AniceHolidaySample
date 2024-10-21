//
//  OrderModel.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/6/29.
//

import Foundation

//airtable上傳資料是record的陣列
struct OrderRequest: Codable, AirtableResponse {
    let records: [OrderRecord]
}

struct OrderRecord: Identifiable, Codable {
    let id: String?
    var fields: OrderItem
}

struct OrderItem: Identifiable, Codable {
    var id: String?
    var orderId: String?
    var customerName: String?
    var item: String
    var quantity: Int
    var sweetness: String
    var temperature: String
    var topping: String?
    var price: Int
    var orderDate: String?

    // 上傳時可以不用id，airtable 會自己生成
    enum CodingKeys: String, CodingKey {
        case customerName, item, quantity, sweetness, temperature, topping, price, orderDate
    }

}

struct CustomerOrderResponse: Codable, AirtableResponse {
    let records: [CustomerOrderRecord]
}

struct CustomerOrderRecord: Identifiable, Codable {
    let id: String?
    var fields: CustomerOrder
}

struct CustomerOrder: Identifiable, Codable {
    var id: String?
    var customerName: String
    var phoneNumber: String
    var address: String
    var totalAmount: Int
    var note: String?
    var orderDate: String
    var orderItems: [String]?

    var pricesFromItems: [Int]?
    var toppingsFromItems: [String]?
    var temperaturesFromItems: [String]?
    var sweetnessesFromItems: [String]?
    var quantitiesFromItems: [Int]?
    var itemsFromItems: [String]?

    enum CodingKeys: String, CodingKey {
        case customerName = "Customer Name"
        case phoneNumber = "Phone Number"
        case address = "Address"
        case totalAmount = "Total Amount"
        case note = "Note"
        case orderDate = "Order Date"
        case orderItems = "Order Items"

        case pricesFromItems = "price (from items)"
        case toppingsFromItems = "topping (from items)"
        case temperaturesFromItems = "temperature (from items)"
        case sweetnessesFromItems = "sweetness (from items)"
        case quantitiesFromItems = "quantity (from items)"
        case itemsFromItems = "item (from items)"
    }
}

// 用於 Airtable 修改請求的模型
struct updateRequest: Codable {
    let fields: OrderItemUpdate
}

struct OrderItemUpdate: Codable {
    var item: String?
    var quantity: Int?
    var sweetness: String?
    var temperature: String?
    var topping: String?
    var price: Int?

    // 只編碼非 nil 的字段
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(item, forKey: .item)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(sweetness, forKey: .sweetness)
        try container.encodeIfPresent(temperature, forKey: .temperature)
        try container.encodeIfPresent(topping, forKey: .topping)
        try container.encodeIfPresent(price, forKey: .price)
    }
}
