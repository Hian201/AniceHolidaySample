//
//  TeaModel.swift
//  AniceHolidaySample
//
//  Created by So í-hian on 2024/6/22.
//

import Foundation

protocol Customizable {
    var item: String { get }
    var quantity: Int { get set }
}

//airtable傳回資料是record的陣列
struct ResponseData: Codable, AirtableResponse {
    let records: [Record]
    
    // 函數如果沒有排除空的field就需要這個
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        var recordsArray = try container.nestedUnkeyedContainer(forKey: .records)
//        var decodedRecords = [Record]()
//        
//        while !recordsArray.isAtEnd {
//            if let record = try? recordsArray.decode(Record.self) {
//                if !record.fields.item.isEmpty {
//                    decodedRecords.append(record)
//                }
//            } else {
//                _ = try? recordsArray.superDecoder()
//            }
//        }
//        self.records = decodedRecords
//    }
//    
//    
//    enum CodingKeys: String, CodingKey {
//        case records
//    }
}

//airtable新增資料會自動產生id，每個欄位資料會存在field
struct Record: Identifiable, Codable {
    let id: String
    var fields: Drink
}

struct Drink: Identifiable, Codable, Customizable {
    var id:String?
    var item: String
    var quantity: Int = 0
    var categories: String
    var description: String
    var price:Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case item = "Item"
        case categories
        case description = "Description"
        case price = "Price"
    }
}

// 字典分類用初始化結構
struct CategoryGroup: Identifiable {
    var id: String
    let records: [Record]
    
    init(category: String, records: [Record]) {
        self.id = category
        self.records = records
    }
}


/*
let fakeJsonString = """
        {
            "records": [
                {
                    "id": "recSKHk5Rj1ocRVws",
                    "createdTime": "2024-06-20T11:03:43.000Z",
                    "fields": {
                        "categories": "原味茶",
                        "Description": "茶香中帶有淡淡竹子香氣。大杯總糖量40.5克，總熱量177.5大卡。咖啡因總含量低於100毫克，每日攝取限量 300 毫克, 孩童及孕哺婦斟酌食用。 糖量、熱量及咖啡因含量皆以最高值標示。 茶葉產地台灣。",
                        "Item": "竹香翡翠",
                        "Price": 40
                    }
                },
                {
                    "id": "rec4ETLbUjPpqfvTJ",
                    "createdTime": "2024-06-20T11:03:43.000Z",
                    "fields": {
                        "categories": "鮮奶茶",
                        "Item": "烏龍拿鐵",
                        "Price": 70,
                        "Description": "烏龍鮮奶茶，使用鮮乳坊鮮奶。大杯:總糖量29克，總熱量298.7大卡。咖啡因總含量低於90毫克, 每日攝取限量 300 毫克, 孩童及孕哺婦斟酌食用。 糖量,、熱量及咖啡因含量皆以最高值標示。 茶葉產地台灣。\\n"
                    }
                }
            ]
        }
        """
*/

let fakeJsonString = """
{
    "records": [{
        "id": "rec4ETLbUjPpqfvTJ",
        "createdTime": "2024-06-20T11:03:43.000Z",
        "fields": {
            "categories": "鮮奶茶",
            "Description": "烏龍鮮奶茶，使用鮮乳坊鮮奶。大杯:總糖量29克，總熱量298.7大卡。咖啡因總含量低於90毫克, 每日攝取限量 300 毫克, 孩童及孕哺婦斟酌食用。 糖量,、熱量及咖啡因含量皆以最高值標示。 茶葉產地台灣。",
            "Item": "烏龍拿鐵",
            "Price": 70
        }
    }, {
        "id": "recSKHk5Rj1ocRVws",
        "createdTime": "2024-06-20T11:03:43.000Z",
        "fields": {
            "categories": "原味茶",
            "Description": "茶香中帶有淡淡竹子香氣。大杯總糖量40.5克，總熱量177.5大卡。咖啡因總含量低於100毫克，每日攝取限量 300 毫克, 孩童及孕哺婦斟酌食用。 糖量、熱量及咖啡因含量皆以最高值標示。 茶葉產地台灣。",
            "Item": "竹香翡翠",
            "Price": 40
        }
    }, {
        "id": "recSxOs4tk3Bg27AW",
        "createdTime": "2024-06-20T11:03:43.000Z",
        "fields": {}
    }]
}
"""
