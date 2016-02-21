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

public class SQLiteConnection{
    internal var conn: SQLite
    init(filePath:String){
        conn = SQLite(filePath)
    }
    func createTable<T:SSMappable>() -> SSResult<T>{
        let model = T()
        let connector = SSConnector(type: .Scan)
        model.dbMap(connector)
        if !conn.inTransaction {
            conn.beginTransaction()
            defer{
                conn.commit()
            }
            return SSResult<T>(result: conn.createTable(makeCreateStatement(connector, model: model)))
        }
        return SSResult<T>(result: conn.createTable(makeCreateStatement(connector, model: model)))
    }
    func deleteTable<T:SSMappable>() -> SSResult<T> {
        let model = T()
        if !conn.inTransaction {
            conn.beginTransaction()
            defer{
                conn.commit()
            }
            return SSResult<T>(result:conn.deleteTable([model.table]))
        }
        return SSResult<T>(result:conn.deleteTable([model.table]))
    }
    
    func table<T:SSMappable>() -> SSTable<T>{
        return SSTable<T>()
    }
    
    func query<T:SSMappable>() -> [T]{
        return [T()]
    }
    
    func beginTransaction(){
        conn.beginTransaction()
    }
    func commit(){
        conn.commit()
    }
    
    private func makeCreateStatement<T:SSMappable>(connector:SSConnector,model:T) -> String {
        var columns:String = String.empty
        connector.scans.enumerate().forEach{
            let separator = (connector.scans.count-1) == $0.index ? String.empty : ","+String.whiteSpace
            columns += $0.element.createColumnStatement() + separator
        }
        return "CREATE TABLE \(model.table)(\(columns));"
    }
    
    func scan<T:SSMappable>() -> (SSConnector,T){
        let model = T()
        let connector = SSConnector(type: .Scan)
        model.dbMap(connector)
        return (connector,model)
    }
    func mapping<T:SSMappable>() -> T{
        let model = T()
        let connector = SSConnector(type: .Scan)
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
        connector.type = .Map
        model.dbMap(connector)
        return model
    }
}

public protocol SSBase{
    var value: AnyObject? { get set }
}

public class SSConnector {
    var values:[String:AnyObject?]=[:]
    var scans:[SSScan] = []
    var type:SSType
    public init(type:SSType){
        self.type = type
    }
    public subscript (name:String,attrs:CLAttr...) -> SSBase{
        switch self.type {
        case .Map:
            let map = SSMap()
            map.value = values[name]!
            return map
        case .Scan:
            let scan = SSScan(name,attrs: attrs)
            scans.append(scan)
            return scan
        }
    }
}

public enum SSType {
    case Scan
    case Map
}

public enum CLType{
    case CL_Integer
    case CL_Text
    case CL_Real
//    case CL_BLOB
}

public enum CLAttr{
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




