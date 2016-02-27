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
    deinit {
        print("SQLiteConnection is deinit!!!")
    }
    func createTable<T:SSMappable>() -> SSResult<T>{
        let model = T()
        let connector = SSConnector(type: .Scan)
        model.dbMap(connector)
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result: self.conn.createTable(self.makeCreateStatement(connector, model: model)))
        }
    }
    func deleteTable<T:SSMappable>() -> SSResult<T> {
        let model = T()
        return executeInTransaction{
            [unowned self] in
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
            [unowned self] in
            let table = SSTable<T>()
            let results = self.conn.select(self.makeSelectAllStatement(T()), values: nil)
            for result in results {
                connector.values = result
                let model = T()
                model.dbMap(connector)
                table.records.append(model)
            }
            return table
        }
    }
    
    func insert<T:SSMappable>(model:T) -> SSResult<T> {
        let connector = SSConnector(type:.Scan)
        model.dbMap(connector)
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result:self.conn.insert(self.makeInsertStatement(connector,model: model), values:self.getValues(connector)))
        }
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
    
    private func makeInsertStatement<T:SSMappable>(connector:SSConnector, model:T) -> String {
        var columns = String.empty
        var count = 0
        connector.scans.enumerate().forEach{
            if let _ = $0.element.value {
                let separator = (connector.scans.count-1) == $0.index ? String.empty : ","+String.whiteSpace
                columns += $0.element.name + separator
                count++
            }
        }
        return "INSERT INTO \(model.table)(\(columns)) VALUES(\(makePlaceholderStatement(count)));"
    }
    
    private func getValues(connector:SSConnector) -> [AnyObject] {
        var values: [AnyObject] = []
        connector.scans.enumerate().forEach{
            if let theValue = $0.element.value {
                values.append(theValue)
            }
        }
        return values
    }
    
    private func makePlaceholderStatement(count:Int) -> String {
        var rtn = String.empty
        for i in 0..<count {
            rtn += "?"
            if i != count-1 {
                rtn.append(Character(","))
            }
        }
        return rtn
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




