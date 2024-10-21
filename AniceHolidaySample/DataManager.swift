//
//  DataManager.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/7/2.
//

import Foundation

protocol AirtableResponse: Codable {
    associatedtype RecordType: Codable
    var records: [RecordType] { get }
}

class DataManager: ObservableObject {
    @Published var cartItems: [OrderItem] = []
    @Published var menuItems: [Record] = []

    @Published var purchasedList: [CustomerOrderRecord] = []
    @Published var purchasedItems: [OrderItem] = []
    
    @Published var isUpdating: Bool = false

    var menuSort = ["原味茶", "風味茶", "奶茶", "芝士奶蓋", "冬瓜茶", "鮮奶茶", "袋子與其他"]

    var groupedItems: [CategoryGroup] {
        let grouped = Dictionary(grouping: menuItems, by: { $0.fields.categories })
        return menuSort.compactMap { category in
            guard let records = grouped[category] else { return nil }
            return CategoryGroup(category: category, records: records)
        }
    }

    //MARK: Network

    enum dataControllerError: Error, LocalizedError {
        case dataNotFound
        case orderCreationFailed
        case orderUpdateFailed
        case orderDeletionFailed

        var localizedDescription: String {
            switch self {
            case .dataNotFound:
                return "找不到資料"
            case .orderCreationFailed:
                return "上傳失敗"
            case .orderUpdateFailed:
                return "資料更新失敗"
            case .orderDeletionFailed:
                return "刪除失敗"
            }
        }
    }

    let baseURL = URL(string: "https://api.airtable.com/v0/appKgJCDZqEcodSFT/")!
    
    
    func fetchTableData<T: AirtableResponse & Decodable>(
        tableName: String, filterFormula: String? = nil, setData: @escaping (T) -> Void
    ) {
        var urlString = "\(baseURL.appending(path: tableName))"

        if let formula = filterFormula {
            let encodedFormula =
                formula.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString += "?filterFormula=\(encodedFormula)"
        }

        guard let dataURL = URL(string: urlString) else {
            print("invalid URL")
            return
        }

        var request = URLRequest(url: dataURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in

            guard let data = data else {
                print("No data")
                return
            }
            print("原始響應數據:")
            self.prettyPrintedJSONString(from: data)

            do {
                // 首先解析 JSON 為字典
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: [])
                    as? [String: Any],
                    let records = jsonResult["records"] as? [[String: Any]]
                {

                    // 篩選記錄
                    let filteredRecords = records.filter { record in
                        guard let fields = record["fields"] as? [String: Any] else { return false }
                        // 這裡可以添加更多的篩選條件
                        //                        return !fields.isEmpty && fields["item"] != nil
                        return !fields.isEmpty
                    }

                    // 創建新的 JSON 數據
                    let filteredData = try JSONSerialization.data(
                        withJSONObject: ["records": filteredRecords], options: [])

                    let decoder = JSONDecoder()
                    let dataResponse = try decoder.decode(T.self, from: filteredData)
                    DispatchQueue.main.async {
                        setData(dataResponse)
                    }
                }
            } catch {
                //                print(error.localizedDescription)
                print("表格獲取失敗：", error)

                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("找不到鍵: \(key.stringValue), 路徑: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("找不到值: \(type), 路徑: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("類型不匹配: \(type), 路徑: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("數據損壞: \(context)")
                    @unknown default:
                        print("未知解碼錯誤")
                    }
                }

            }
        }.resume()
    }

    // 嘗試用order的id來抓order items的對應資料
    //    func fetchSpecificItems(itemsID: [String]) {
    //        let formula = "OR(" + itemsID.map{ "RECORD_ID = '\($0)" }.joined(separator: ",") + ")"
    //        fetchTableData(tableName: "Order items", filterFormula: formula) { (response: OrderRequest) in
    //            self.purchasedItems = response.records.map{ $0.fields }
    //        }
    //    }
    func fetchSpecificItems(itemsID: [String], completion: @escaping (Bool) -> Void) {
        let formula = "{Order ID} = '\(itemsID[0])'"
        fetchTableData(tableName: "Order items", filterFormula: formula) {
            (response: OrderRequest?) in
            if let response = response {
                self.purchasedItems = response.records.compactMap { record -> OrderItem? in
                    do {
                        let jsonData = try JSONEncoder().encode(record.fields)
                        let item = try JSONDecoder().decode(OrderItem.self, from: jsonData)
                        return item
                    } catch {
                        print("解碼記錄時出錯: \(error)")
                        return nil
                    }
                }

                // 更新 purchasedList
                if let updatedOrder = self.purchasedList.first(where: { $0.fields.id == itemsID[0] }
                ) {
                    var newFields = updatedOrder.fields
                    newFields.itemsFromItems = self.purchasedItems.map { $0.item }
                    newFields.quantitiesFromItems = self.purchasedItems.map { $0.quantity }
                    newFields.sweetnessesFromItems = self.purchasedItems.map { $0.sweetness }
                    newFields.temperaturesFromItems = self.purchasedItems.map { $0.temperature }
                    newFields.toppingsFromItems = self.purchasedItems.map { $0.topping ?? "不加料" }
                    newFields.pricesFromItems = self.purchasedItems.map { $0.price }

                    if let index = self.purchasedList.firstIndex(where: {
                        $0.fields.id == itemsID[0]
                    }) {
                        self.purchasedList[index].fields = newFields
                    }
                }

                completion(true)
            } else {
                completion(false)
            }
        }
    }

    /*
     func fetchSpecificItem(itemsID: [String], completion: @escaping (Bool) -> Void) {
     // 不再需要構建特定的過濾公式，因為我們會在客戶端進行篩選
     let formula = ""
     print("開始獲取訂單項目，訂單 ID: \(itemsID)")

     fetchTableData(tableName: "Order items", filterFormula: formula) { (response: OrderRequest?) in
     if let response = response {
     self.purchasedItems = response.records.compactMap { record -> OrderItem? in
     do {
     let jsonData = try JSONEncoder().encode(record.fields)
     var item = try JSONDecoder().decode(OrderItem.self, from: jsonData)

     // 檢查 Order ID 是否匹配
     if let orderIDs = item.orderId, !Set(orderIDs).isDisjoint(with: itemsID) {
     item.id = record.id // 確保設置正確的 ID
     return item
     } else {
     return nil // 如果 Order ID 不匹配，則排除此項目
     }
     } catch {
     print("解碼記錄時出錯: \(error)")
     return nil
     }
     }

     print("成功獲取 \(self.purchasedItems.count) 個訂單項目")
     completion(true)
     } else {
     print("Order items 獲取失敗")
     completion(false)
     }
     }
     }
     */

    //    func updateOrderedItems(item: OrderItem) -> <#return type#> {
    //        <#function body#>
    //    }

    //MARK: History Orders
    func orderHistorySort(orderData: [CustomerOrderRecord]) -> [CustomerOrderRecord] {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let sortedRecords = orderData.map { record -> (Date, CustomerOrderRecord) in
            let date = iso8601Formatter.date(from: record.fields.orderDate) ?? Date.distantPast
            return (date, record)
        }
        .sorted { $0.0 > $1.0 }
        .enumerated()
        .map { index, tuple -> CustomerOrderRecord in
            let (date, record) = tuple
            var updatedRecord = record
            updatedRecord.fields.id = "\(index)"
            //                updatedRecord.fields.orderDate = dateFormatter.string(from: date)
            updatedRecord.fields.orderDate = dateFormation(date: date)
            return updatedRecord
        }

        return sortedRecords
    }

    func dateFormation(date: Date) -> String {
        let calender = Calendar.current
        let now = Date()

        let dateFormatter = DateFormatter()

        if calender.isDateInToday(date) {
            dateFormatter.dateFormat = "HH:mm"
            return "Today, " + dateFormatter.string(from: date)
        } else if calender.isDateInYesterday(date) {
            dateFormatter.dateFormat = "HH:mm"
            return "Yesterday, " + dateFormatter.string(from: date)
        } else if calender.isDate(date, equalTo: now, toGranularity: .year) {
            dateFormatter.dateFormat = "M-d, HH:mm"
            return dateFormatter.string(from: date)
        } else {
            dateFormatter.dateFormat = "yyyy-M-d"
            return dateFormatter.string(from: date)
        }
    }

    //    func groupItems(menuData: [Record]) -> [CategoryGroup] {
    //        let menuSort = ["原味茶", "風味茶", "奶茶", "芝士奶蓋", "冬瓜茶", "鮮奶茶", "袋子與其他"]
    //        let grouped = Dictionary(grouping: menuData, by: { $0.fields.categories })
    //        return menuSort.compactMap { category in
    //            guard let records = grouped[category] else { return nil }
    //            return CategoryGroup(category: category, records: records)
    //        }
    //    }

    //    func groupItems(menuData: [Record]) {
    //        let menuSort = ["原味茶", "風味茶", "奶茶", "芝士奶蓋", "冬瓜茶", "鮮奶茶", "袋子與其他"]
    //        let grouped = Dictionary(grouping: menuData, by: { $0.fields.categories })
    //        menuItems = menuSort.compactMap { category in
    //            guard let records = grouped[category] else { return nil }
    //            return CategoryGroup(category: category, records: records)
    //        }
    //    }

    /*
     func createCartRecords(buyerName: String) -> OrderRequest {
     let dateFormater = ISO8601DateFormatter()
     dateFormater.formatOptions = [ .withInternetDateTime, .withFractionalSeconds]
     let currentDate = dateFormater.string(from: Date())

     let records =  cartItems.map { drink -> OrderRecord in
     var updatedDrink = drink
     updatedDrink.customerName = buyerName
     updatedDrink.orderDate = currentDate
     return OrderRecord(id: nil, fields: updatedDrink)
     }
     return OrderRequest(records: records)
     }



     func createOrderRecords(customer: String, phoneNum: String, address: String, note: String, amount: Int) -> CustomerOrderResponse {
     let dateFormater = ISO8601DateFormatter()
     dateFormater.formatOptions = [ .withInternetDateTime, .withFractionalSeconds]
     let currentDate = dateFormater.string(from: Date())

     print("Formatted date: \(currentDate)")

     let orderRecords = CustomerOrderResponse(
     records: [.init(
     id: nil,
     fields: .init(
     customerName: customer,
     phoneNumber: phoneNum,
     address: address,
     totalAmount: amount,
     note: note,
     orderDate: currentDate
     )
     )]
     )
     return orderRecords
     }



     func uploadItems(customerName: String) {
     let itemsURL = baseURL.appending(path: "Order items")
     var request = URLRequest(url: itemsURL)
     request.httpMethod = "POST"
     request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
     request.setValue("application/json", forHTTPHeaderField: "Content-Type")

     let allRecords = createCartRecords(buyerName: customerName).records
     let batches = stride(from: 0, to: allRecords.count, by: 10).map {
     Array(allRecords[$0 ..< min($0 + 10, allRecords.count)])
     }

     for (index, batch) in batches.enumerated() {
     let batchRequest = OrderRequest(records: batch)
     let encoder = JSONEncoder()
     let jsonData = try? encoder.encode(batchRequest)
     request.httpBody = jsonData

     URLSession.shared.dataTask(with: request) { data, response, error in

     guard let data = data,
     let content = String(data: data, encoding: .utf8) else { return }
     print("Response body: \(content)")

     guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
     print("drink:", dataControllerError.orderUpdateFailed)
     return
     }

     if index == batches.count - 1 {
     DispatchQueue.main.async {
     self.cartItems.removeAll()
     }
     }

     }.resume()
     }
     }

     func uploadOrder(createdRecords: CustomerOrderResponse, customerName: String) {
     let orderURL = baseURL.appending(path: "Order")
     var request = URLRequest(url: orderURL)
     request.httpMethod = "POST"
     request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
     request.setValue("application/json", forHTTPHeaderField: "Content-Type")

     let encoder = JSONEncoder()
     let jsonData = try? encoder.encode(createdRecords)
     request.httpBody = jsonData

     URLSession.shared.dataTask(with: request) { data, response, error in
     if let error = error {
     print(error)
     return
     }

     //            guard let data = data,
     //                  let content = String(data: data, encoding: .utf8) else { return }
     //            print("Response body: \(content)")

     if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
     print("Order uploaded successfully")
     self.uploadItems(customerName: customerName)
     } else {
     print("Failed to upload order")
     }

     }.resume()
     }
     */

    // MARK: new batch
    func uploadOrderAndItems(customerName: String, phoneNum: String, address: String, note: String)
    {
        let orderURL = baseURL.appending(path: "Order")
        var orderRequest = URLRequest(url: orderURL)
        orderRequest.httpMethod = "POST"
        orderRequest.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
        orderRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let currentDate = dateFormatter.string(from: Date())

        let totalAmount = self.totalAmount()

        let orderRecords = CustomerOrderResponse(
            records: [
                .init(
                    id: nil,
                    fields: .init(
                        customerName: customerName,
                        phoneNumber: phoneNum,
                        address: address,
                        totalAmount: totalAmount,
                        note: note,
                        orderDate: currentDate,
                        orderItems: []  // 暫時是空的，稍後會更新
                    )
                )
            ]
        )

        let encoder = JSONEncoder()
        let orderData = try? encoder.encode(orderRecords)
        orderRequest.httpBody = orderData

        URLSession.shared.dataTask(with: orderRequest) { data, response, error in
            if let error = error {
                print("訂單上傳錯誤：", error)
                return
            }

            guard let data = data,
                let orderResponse = try? JSONDecoder().decode(
                    CustomerOrderResponse.self, from: data),
                let orderId = orderResponse.records.first?.id
            else {
                print("無法解析訂單回應")
                return
            }

            self.uploadOrderItemsBatch(
                orderId: orderId, customerName: customerName, currentDate: currentDate)
        }.resume()
    }

    // 設定每批10個
    private func uploadOrderItemsBatch(orderId: String, customerName: String, currentDate: String) {
        let batchSize = 10  // Airtable 的字段限制
        let batches = stride(from: 0, to: cartItems.count, by: batchSize).map {
            Array(cartItems[$0..<min($0 + batchSize, cartItems.count)])
        }

        let group = DispatchGroup()
        var uploadedItemIds: [String] = []

        for batch in batches {
            group.enter()
            uploadBatch(
                orderId: orderId, items: batch, customerName: customerName, currentDate: currentDate
            ) { itemIds in
                if let ids = itemIds {
                    uploadedItemIds.append(contentsOf: ids)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.updateOrderWithItems(orderId: orderId, itemIds: uploadedItemIds)
        }
    }

    // 每批次的上傳處理
    private func uploadBatch(
        orderId: String, items: [OrderItem], customerName: String, currentDate: String,
        completion: @escaping ([String]?) -> Void
    ) {
        let itemsURL = baseURL.appending(path: "Order items")
        var itemsRequest = URLRequest(url: itemsURL)
        itemsRequest.httpMethod = "POST"
        itemsRequest.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
        itemsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let orderItems = items.map { drink -> OrderItem in
            var newItem = drink
            newItem.id = orderId
            newItem.customerName = customerName
            newItem.orderDate = currentDate
            return newItem
        }

        let encoder = JSONEncoder()

        let itemRecords = orderItems.map { OrderRecord(id: nil, fields: $0) }
        let itemsData = try? encoder.encode(OrderRequest(records: itemRecords))
        itemsRequest.httpBody = itemsData

        URLSession.shared.dataTask(with: itemsRequest) { data, response, error in
            if let error = error {
                print("訂單項目上傳錯誤：", error)
                completion(nil)
                return
            }

            guard let data = data,
                let itemsResponse = try? JSONDecoder().decode(OrderRequest.self, from: data)
            else {
                print("無法解析訂單項目回應")
                completion(nil)
                return
            }

            let itemIds = itemsResponse.records.compactMap { $0.id }
            completion(itemIds)
        }.resume()
    }

    // 把 order items 的飲料 link 到 Order 表格的對應訂單
    private func updateOrderWithItems(orderId: String, itemIds: [String]) {
        let orderURL = baseURL.appending(path: "Order/\(orderId)")
        var request = URLRequest(url: orderURL)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updateData = ["fields": ["Order Items": itemIds]]
        let encoder = JSONEncoder()
        request.httpBody = try? encoder.encode(updateData)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("更新訂單連結錯誤：", error)
                return
            }

            print("訂單與訂單項目成功連結")

            DispatchQueue.main.async {
                self.cartItems.removeAll()
                self.objectWillChange.send()
            }
        }.resume()
    }

    // MARK: Cart

    func addToCart(
        drink: Drink, sweetness: String, temperature: String, topping: String, quantity: Int,
        totalPrice: Int
    ) {
        if let index = cartItems.firstIndex(where: {
            $0.item == drink.item && $0.sweetness == sweetness && $0.temperature == temperature
                && $0.topping == topping
        }) {
            cartItems[index].quantity += quantity
            cartItems[index].price = cartItems[index].price + totalPrice
        } else {
            let newItem = OrderItem(
                id: UUID().uuidString, customerName: nil, item: drink.item, quantity: quantity,
                sweetness: sweetness, temperature: temperature, topping: topping, price: totalPrice)
            cartItems.append(newItem)
        }
        print("Cart updated. Current items: \(cartItems)")
    }

    func upadteCartItam(updateItem: OrderItem) {
        if let index = cartItems.firstIndex(where: { $0.item == updateItem.item }) {
            cartItems[index] = updateItem
        }
    }

    func totalAmount() -> Int {
        return cartItems.reduce(0) { $0 + $1.price }
    }

    func totalQuantity() -> Int {
        return cartItems.reduce(0) { $0 + $1.quantity }
    }

    //MARK: Data check
    func getDrink(for itemName: String) -> Drink? {
        return menuItems.first { $0.fields.item == itemName }?.fields
    }

    func prettyPrintedJSONString(from data: Data) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonData = try? JSONSerialization.data(
                withJSONObject: jsonObject, options: [.prettyPrinted]),
            let prettyJSONString = String(data: jsonData, encoding: .utf8)
        else {
            print("Failed to read JSON Object.")
            return
        }
        print(prettyJSONString)
    }
}

func decodeJsonData<T: Decodable>(_ data: Data) -> T {
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError()
    }
}

extension DataManager {

    //MARK: PATCH Order
    func updateOrderItem(
        itemId: String, data: updateRequest,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let url = baseURL.appending(path: "Order items").appendingPathComponent(itemId)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try? JSONEncoder().encode(data)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if data != nil {
                completion(.success("修改成功"))
                if let content = String(data: data!, encoding: .utf8) {
                    print("Response body: \(content)")
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func updateOrderTotal(orderId: String, newTotalAmount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let orderURL = baseURL.appending(path: "Order/\(orderId)")
        var request = URLRequest(url: orderURL)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let updateData = ["fields": ["Total Amount": newTotalAmount]]
        let encoder = JSONEncoder()
        request.httpBody = try? encoder.encode(updateData)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    let error = NSError(domain: "AirtableError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to update total amount"])
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "AirtableError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
            }
        }.resume()
    }

    func modifyPurchasedList(orderId: String, updatedItem: OrderItem) {
        if let orderIndex = purchasedList.firstIndex(where: { $0.id == orderId }) {
            var orderFields = purchasedList[orderIndex].fields
            
            if let itemIndex = orderFields.itemsFromItems?.firstIndex(of: updatedItem.item) {
                // 更新現有項目
                orderFields.pricesFromItems?[itemIndex] = updatedItem.price
                orderFields.quantitiesFromItems?[itemIndex] = updatedItem.quantity
                orderFields.sweetnessesFromItems?[itemIndex] = updatedItem.sweetness
                orderFields.temperaturesFromItems?[itemIndex] = updatedItem.temperature
                orderFields.toppingsFromItems?[itemIndex] = updatedItem.topping ?? "不加料"
                
                // 重新計算總金額
                let newTotalAmount = (orderFields.pricesFromItems ?? []).reduce(0, +)
                orderFields.totalAmount = newTotalAmount
                
                // 更新 purchasedList 中的訂單
                purchasedList[orderIndex].fields = orderFields
            } else {
                print("在訂單 \(orderId) 中找不到項目 \(updatedItem.item)")
            }
        } else {
            print("找不到訂單 ID: \(orderId)")
        }
    }

    //MARK: Delete order
    func deleteOrder(at offset: IndexSet) {
        for index in offset {
            let orderToDelete = purchasedList[index]
            let orderToDeleteID = orderToDelete.id
            let orderToDeleteDrinksID = orderToDelete.fields.orderItems
            deleteDataFromTables(orderId: orderToDeleteID!, itemId: orderToDeleteDrinksID ?? [""]) { suceess in
                if suceess {
                    DispatchQueue.main.async {
                        self.purchasedList.remove(at: index)
                    }
                }
            }
        }
    }
    
    func deleteDataFromTables(orderId: String, itemId: [String], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var orderDeletionSuceess = false
        var itemDeletionSuccess = false
        
        group.enter()
        deleteOrderFromServer(orderId: orderId) { success in
            orderDeletionSuceess = success
            group.leave()
        }
        
        group.enter()
        deleteDrinkFromServer(itemId: itemId) { success in
            itemDeletionSuccess = success
            group.leave()
        }
        group.notify(queue: .main) {
            completion(orderDeletionSuceess && itemDeletionSuccess)
        }
    }
    
    func deleteOrderFromServer(orderId: String, completion: @escaping (Bool) -> Void) {
        let url = baseURL.appending(path: "Order").appendingPathComponent(orderId)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Order Delete success")
            } else {
                print(error!.localizedDescription)
            }
        }.resume()
    }
    


    func deleteDrinkFromServer(itemId: [String], completion: @escaping (Bool) -> Void) {
        let batchSize = 10
        let batches = stride(from: 0, to: itemId.count, by: batchSize).map {
            Array(itemId[$0..<min($0 + batchSize, itemId.count)])
        }
        
        let group = DispatchGroup()
        var allsucceeded = true
        
        for batch in batches {
            group.enter()
            deleteDrinkBatch(itemId: batch) { success in
                if !success {
                    allsucceeded = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allsucceeded)
        }
        
    }
    
    func deleteDrinkBatch(itemId: [String], completion: @escaping (Bool) -> Void) {
        let multiRecords = itemId.map { "records[]=\($0)" }.joined(separator: "&")
        let urlString = baseURL.appendingPathComponent("Order items").absoluteString + "?\(multiRecords)"
        
        guard let url = URL(string: urlString) else {
            print("無效的 URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(APIKey.default)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error {
                print("Error: \(error.localizedDescription)")
            } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Ordered Drink Delete success")
            } else {
                print("Failed to delete records")
            }
            
            /*
            if let error = error {
                print("錯誤：\(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("無效的回應")
                completion(false)
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("成功刪除訂購的飲料")
                completion(true)
            } else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("刪除記錄失敗。狀態碼：\(httpResponse.statusCode)")
                    print("回應：\(responseString)")
                } else {
                    print("刪除記錄失敗。狀態碼：\(httpResponse.statusCode)")
                }
                completion(false)
            }
            */

            
        }.resume()
         
    }
    
}
