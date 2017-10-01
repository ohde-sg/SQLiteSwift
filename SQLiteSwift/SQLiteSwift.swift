//
//  SQLiteSwift.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public protocol SSMappable {
    static var table:String { get }
    func dbMap(_ connector:SSConnector)
    init()
}

open class SQLiteConnection{
    internal var conn: SQLite
    open var isOutput:Bool {
        set{ conn.isOutput = newValue }
        get{ return conn.isOutput }
    }
    public init(filePath:String){
        conn = SQLite(filePath)
    }
    deinit {
        print("SQLiteConnection is deinit!!!")
    }
    
    open func isExistTable<T:SSMappable>() -> SSResult<T> {
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result: self.conn.isExistTable([T.table]).result)
        }
    }
    
    open func createTable<T:SSMappable>() -> SSResult<T>{
        let model = T()
        let connector = SSConnector(type: .scan)
        model.dbMap(connector)
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result: self.conn.createTable(self.makeCreateStatement(connector, model: model)))
        }
    }
    open func deleteTable<T:SSMappable>() -> SSResult<T> {
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result:self.conn.deleteTable([T.table]))
        }
    }
    
    fileprivate func executeInTransaction<T>(_ execute:()->T) -> T{
        if !conn.inTransaction {
            conn.beginTransaction()
            defer {
                conn.commit()
            }
            return execute()
        }
        return execute()
    }
    
    open func table<T:SSMappable>() -> SSTable<T>{
        let connector = SSConnector(type: .map)
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
    
    open func insert<T:SSMappable>(_ model:T) -> SSResult<T> {
        let connector = SSConnector(type:.scan)
        model.dbMap(connector)
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result:self.conn.insert(self.makeInsertStatement(connector,model: model), values:self.getValues(connector)))
        }
    }
    
    open func update<T:SSMappable>(_ model:T) -> SSResult<T> {
        let connector = SSConnector(type:.scan)
        model.dbMap(connector)
        guard let thePKey = getPrimaryKey(connector)?.value else{
            return SSResult<T>(result: false)
        }
        
        return executeInTransaction{
            [unowned self] in
            var values = self.getAllValue(connector)
            values.append(thePKey)
            return SSResult<T>(result:self.conn.update(
                self.makeUpdateStatement(connector,model: model),values:values)
            )
        }
    }
    
    open func query<T:SSMappable>(_ query:String,params:[AnyObject]) -> SSTable<T>{
        let connector = SSConnector(type: .map)
        return executeInTransaction{
            [unowned self] in
            let table = SSTable<T>()
            let results = self.conn.select(query, values: params)
            for result in results {
                connector.values = result
                let model = T()
                model.dbMap(connector)
                table.records.append(model)
            }
            return table
        }
    }
    
    open func delete<T:SSMappable>(_ model:T) -> SSResult<T> {
        let connector = SSConnector(type:.scan)
        model.dbMap(connector)
        guard let theKey = getPrimaryKey(connector)?.value else{
            return SSResult<T>(result: false)
        }
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result:self.conn.delete(self.makeDeleteStatement(connector,model: model),values: [theKey]))
        }
    }
    
    open func beginTransaction(){
        conn.beginTransaction()
    }
    open func commit(){
        conn.commit()
    }
    open func rollback(){
        conn.rollback()
    }
    
    fileprivate func getPrimaryKey(_ connector:SSConnector) -> SSScan? {
        for item in connector.scans{
            if item.isPrimaryKey && item.value != nil {
                return item
            }
        }
        return nil
    }
    
    fileprivate func makeUpdateStatement<T:SSMappable>(_ connector:SSConnector, model:T) -> String {
        var columns = String.empty
        let scans = removePrimaryKey(connector)
        let count = scans.count
        scans.enumerated().forEach{
            let separator = count-1 == $0.offset ? String.empty : ","+String.whiteSpace
            columns += "\($0.element.name)=?" + separator
        }
        let theKey = getPrimaryKey(connector)!
        return "UPDATE \(T.table) SET \(columns) WHERE \(theKey.name)=?;"
    }
    
    fileprivate func makeCreateStatement<T:SSMappable>(_ connector:SSConnector,model:T) -> String {
        var columns:String = String.empty
        connector.scans.enumerated().forEach{
            let separator = (connector.scans.count-1) == $0.offset ? String.empty : ","+String.whiteSpace
            columns += $0.element.createColumnStatement() + separator
        }
        return "CREATE TABLE \(T.table)(\(columns));"
    }
    
    fileprivate func makeSelectAllStatement<T:SSMappable>(_ model:T) -> String {
        return "SELECT * From \(T.table);"
    }
    
    fileprivate func makeInsertStatement<T:SSMappable>(_ connector:SSConnector, model:T) -> String {
        var columns = String.empty
        let count = connector.scans.count{ $0.value != nil }
        connector.scans.select{ $0.value != nil }.enumerated().forEach{
            let separator = count-1 == $0.offset ? String.empty : ","+String.whiteSpace
            columns += $0.element.name + separator
        }
        return "INSERT INTO \(T.table)(\(columns)) VALUES(\(makePlaceholderStatement(count)));"
    }
    
    fileprivate func makeDeleteStatement<T:SSMappable>(_ connector:SSConnector,model:T) -> String {
        let theKey = getPrimaryKey(connector)!
        return "DELETE FROM \(T.table) WHERE \(theKey.name)=?;"
    }
    
    fileprivate func getValues(_ connector:SSConnector) -> [AnyObject] {
        var values: [AnyObject] = []
        connector.scans.enumerated().forEach{
            if let theValue = $0.element.value {
                values.append(theValue)
            }
        }
        return values
    }
    
    fileprivate func getAllValue(_ connector:SSConnector) -> [AnyObject] {
        return removePrimaryKey(connector).map{
            if let theValue = $0.value {
                return theValue
            }
            return NSNull()
        }
    }
    
    fileprivate func removePrimaryKey(_ connector:SSConnector) -> [SSScan] {
        var scans = connector.scans
        for scan in scans.enumerated() {
            if scan.element.isPrimaryKey { scans.remove(at: scan.offset) }
        }
        return scans
    }
    
    fileprivate func makePlaceholderStatement(_ count:Int) -> String {
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
        let connector = SSConnector(type: .scan)
        model.dbMap(connector)
        return (connector,model)
    }
    func mapping<T:SSMappable>() -> T{
        let model = T()
        let connector = SSConnector(type: .scan)
        model.dbMap(connector)
        var values:[String:AnyObject] = [:]
        for item in connector.scans.enumerated() {
            switch item.element.type! {
            case .cl_Integer:
                values[item.element.name] = 0 as AnyObject
            case .cl_Text:
                values[item.element.name] = "sample\(item.offset)" as AnyObject
            default:
                break
            }
        }
        connector.values = values
        connector.type = .map
        model.dbMap(connector)
        return model
    }
}

/// Use for let work to column. e.g) scan column info, mapping value to column variables
public protocol SSWorker{
    var value: AnyObject? { get set }
    func work<T>(_ lhs:inout T?)
}

open class SSConnector {
    var values:[String:AnyObject?]=[:]
    var scans:[SSScan] = []
    var type:SSType
    public init(type:SSType){
        self.type = type
    }
    open subscript (name:String,attrs:CLAttr...) -> SSWorker{
        switch self.type {
        case .map:  // return map worker
            let map = SSMap()
            if let theValue = values[name]{
                map.value = theValue
            }
            return map
        case .scan: // return scan worker
            let scan = SSScan(name,attrs: attrs)
            scans.append(scan)
            return scan
        }
    }
}

public enum SSType {
    case scan
    case map
}

public enum CLType{
    case cl_Integer
    case cl_Text
    case cl_Real
//    case CL_BLOB
}

public enum CLAttr{
    case primaryKey
    case autoIncrement
    case notNull
    case unique
    case `default`(AnyObject)
    case check(String)
}

public func == (lhs:CLAttr,rhs:CLAttr) -> Bool{
    switch (lhs,rhs) {
    case (.primaryKey,.primaryKey):
        return true
    case (.autoIncrement,.autoIncrement):
        return true
    case (.notNull,.notNull):
        return true
    case (.unique,.unique):
        return true
    case (.default,.default):
        return true
    case (.check,.check):
        return true
    default:
        return false
    }
}

precedencegroup WorkPrecedence {
    associativity: none
}
infix operator <- : WorkPrecedence

public func <- <T>(lhs:inout T?,rhs:SSWorker){
    rhs.work(&lhs)
}
import Swift



