//
//  SQLiteSwift.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public protocol SSMappable {
    var table:String { get }
    func dbMap(connector:SSConnector)
    init()
}

public class SQLiteConnection<T:SSMappable> {
    var conn: SQLite
    init(filePath:String){
        conn = SQLite(filePath)
    }
    func createTable() -> Bool{
        let model = T()
        let connector = SSConnector()
        model.dbMap(connector)
        for item in connector.scans {
            print(item.type,item.name,item.attrs)
        }
        return false
    }
    func scan() -> SSConnector{
        let model = T()
        let connector = SSConnector()
        model.dbMap(connector)
        return connector
    }
    func mapping() -> T{
        let model = T()
        let connector = SSConnector()
        model.dbMap(connector)
        var values:[String:AnyObject] = [:]
        for item in connector.scans.enumerate() {
            switch item.element.type! {
            case .CL_Integer:
                values[item.element.name] = 0
            case .CL_Text:
                values[item.element.name] = "sample\(item.index)"
            default:
                break
            }
        }
        connector.values = values
        model.dbMap(connector)
        return model
    }
}

public protocol SSBase{
    var value: AnyObject? { get set }
}

public class SSMap: SSBase{
    public var value : AnyObject?
}

public class SSScan: SSBase{
    var attrs:[CLAttr]
    var type: CLType?
    public var value:AnyObject?
    var name:String
    init(_ name:String, attrs:[CLAttr]){
        self.name = name
        self.attrs = attrs
    }
}

public class SSConnector {
    var values:[String:AnyObject?]?
    var scans:[SSScan] = []
    public subscript(name:String,attrs:CLAttr...) -> SSBase{
        if let theValues = values {
            let map = SSMap()
            map.value = theValues[name]!
            return map
        }
        let scan = SSScan(name,attrs: attrs)
        scans.append(scan)
        return scan
    }
}

public enum CLType {
    case CL_Integer
    case CL_Text
    case CL_Real
//    case CL_BLOB
}

public enum CLAttr {
    case PrimaryKey
    case AutoIncrement
    case NotNull
    case Unique
    case Default(AnyObject)
    case Check(String)
}

infix operator <- {
    precedence 20
    associativity none
}

public func <- <T>(inout lhs:T?,rhs:SSBase){
    if rhs is SSScan {
        lhs <- rhs as! SSScan
    }
    if rhs is SSMap {
        lhs <- rhs as! SSMap
    }
}

public func <- <T> (inout lhs:T?,rhs:SSScan) {
    //Integer
    if lhs is Int? {
        rhs.type = CLType.CL_Integer
        rhs.value = lhs as? AnyObject
    }
    if lhs is Bool? {
        rhs.type = CLType.CL_Integer
        if let theLhs = lhs {
            rhs.value = theLhs as! Bool ? 1 : 0
        }
        return
    }
    //Real
    if lhs is Double? || lhs is Float?{
        rhs.type = CLType.CL_Real
    }
    //Text
    if lhs is String? {
        rhs.type = CLType.CL_Text
    }
    
    if let theLhs = lhs {
        rhs.value = theLhs as? AnyObject
    }
}

public func <- <T>(inout lhs:T?,rhs:SSMap) {
    lhs = rhs.value as? T
}
public func <- (inout lhs:Bool?,rhs:SSMap) {
    let val:Int = rhs.value as! Int
    lhs = (val != 0)
}




