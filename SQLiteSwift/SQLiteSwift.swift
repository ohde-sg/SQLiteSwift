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
        return executeInTransaction{
            return SSResult<T>(result: self.conn.createTable(self.makeCreateStatement(connector, model: model)))
        }
    }
    func deleteTable<T:SSMappable>() -> SSResult<T> {
        let model = T()
        return executeInTransaction{
            return SSResult<T>(result:self.conn.deleteTable([model.table]))
        }
    }
    
    private func executeInTransaction<T>(execute:()->T) -> T{
        if !conn.inTransaction {
            conn.beginTransaction()
            defer {
                conn.commit()
            }
            return execute()
        }
        return execute()
    }
    
    func table<T:SSMappable>() -> SSTable<T>{
        let connector = SSConnector(type: .Map)
        return executeInTransaction{
            return self.tableInTransaction(connector)
        }
    }
    
    private func tableInTransaction<T:SSMappable> (connector:SSConnector)-> SSTable<T>{
        let table = SSTable<T>()
        let results = conn.select(makeSelectAllStatement(T()), values: nil)
        for result in results {
            connector.values = result
            let model = T()
            model.dbMap(connector)
            table.records.append(model)
        }
        return table
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
    
    private func makeSelectAllStatement<T:SSMappable>(model:T) -> String {
        return "SELECT * From \(model.table);"
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

/// Use for let work to column. e.g) scan column info, mapping value to column variables
public protocol SSWorker{
    var value: AnyObject? { get set }
    func work<T>(inout lhs:T?)
}

public class SSConnector {
    var values:[String:AnyObject?]=[:]
    var scans:[SSScan] = []
    var type:SSType
    public init(type:SSType){
        self.type = type
    }
    public subscript (name:String,attrs:CLAttr...) -> SSWorker{
        switch self.type {
        case .Map:  // return map worker
            let map = SSMap()
            map.value = values[name]!
            return map
        case .Scan: // return scan worker
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

public func <- <T>(inout lhs:T?,rhs:SSWorker){
    rhs.work(&lhs)
}




