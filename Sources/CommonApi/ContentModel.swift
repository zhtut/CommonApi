//
//  File.swift
//  
//
//  Created by zhtg on 2022/8/21.
//

import Vapor
import FluentKit

extension AnyProperty {
    var key: String {
        let desc = "\(self)"
        if desc.contains("key: ") {
            var key = desc.suffix(fromString: "key: ")
            key = key.prefix(toString: ")")
            return key
        }
        return ""
    }
    
    var valueType: Any.Type {
        return type(of: self).anyValueType
    }
}

protocol ContentModel: Model, Content, Validatable {
    static var idKeys: [String] { get }
    static func filterResult<T>(_ result: [T], req: Request) -> [T] where T: ContentModel
    static func filterResult<T>(_ result: [T], id: String) -> T? where T: ContentModel
}

extension ContentModel {
    
    /// 验证参数的类型
    /// - Parameter validations: 验证器
//    func validateType(_ validations: inout Validations) {
//        for pro in properties {
//            if let key = ValidationKey(stringValue: pro.key) {
//                if let type = pro.anyValue as? Decodable.Type {
//                    validations.add(key, as: type, required: false)
//                }
//            }
//        }
//    }
    
    static var idKeys: [String] {
        return [String]()
    }
    
    static func filterResult<T>(_ result: [T], req: Request) -> [T] where T: ContentModel {
        // 先用能用参数key取出值，key包含任意参数，则搜索有效
        var filter = [T]()
        if let key = try? req.query.get(String.self, at: "key") {
            for module in result {
                if module.searchWithKey(key) {
                    filter.append(module)
                }
            }
        } else {
            filter += result
        }
        // 再从剩下的参数中过滤
        if filter.count > 0,
           let first = filter.first {
            for pro in first.properties {
                let key = pro.key
                if let strValue = try? req.query.get(at: key) as String {
                    filter = filter.filter({ $0.propertyEqual(key: key, val: strValue, type: String.self) })
                } else if let intValue = try? req.query.get(at: key) as Int {
                    filter = filter.filter({ $0.propertyEqual(key: key, val: intValue, type: Int.self) })
                } else if let doubleValue = try? req.query.get(at: key) as Double {
                    filter = filter.filter({ $0.propertyEqual(key: key, val: doubleValue, type: Double.self) })
                }
            }
        }
        return filter
    }
    
    static func filterResult<T>(_ result: [T], id: String) -> T? where T: ContentModel {
        for item in result {
            for key in idKeys {
                if "\(item.value(for: key))" == id {
                    return item
                }
            }
        }
        return nil;
    }
    
    /// 判断一个属性是否相等
    /// - Parameters:
    ///   - key: 属性的key
    ///   - val: 属性的值
    ///   - type: 一个可以判断相等的子类
    /// - Returns: 返回是否相等
    func propertyEqual<T: Equatable>(key: String, val: T, type: T.Type) -> Bool {
        if let temp = value(for: key) as? T,
         temp == val {
            return true
        }
        return false
    }
    
    /// 取出属性的值
    /// - Parameter key: 属性的key
    /// - Returns: 返回属性的值
    func value(for key: String) -> Any {
        for pro in self.properties {
            if key == pro.key {
                if let value = pro.anyValue {
                    return value
                }
            }
        }
        return ""
    }
    
    func searchWithKey(_ key: String) -> Bool {
        for pro in self.properties {
            if let value = pro.anyValue {
                let valueStr = "\(value)"
                if valueStr.contains(key) {
                    return true
                }
            }
        }
        return false
    }
}
