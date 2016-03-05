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
    func dbMap(connector:SSConnector)
    init()
}

public class SQLiteConnection{
    internal var conn: SQLite
    public var isOutput:Bool {
        set{ conn.isOutput = newValue }
        get{ return conn.isOutput }
    }
    public init(filePath:String){
        conn = SQLite(filePath)
    }
    deinit {
        print("SQLiteConnection is deinit!!!")
    }
    
    public func isExistTable<T:SSMappable>() -> SSResult<T> {
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result: self.conn.isExistTable([T.table]).result)
        }
    }
    
    public func createTable<T:SSMappable>() -> SSResult<T>{
        let model = T()
        let connector = SSConnector(type: .Scan)
        model.dbMap(connector)
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result: self.conn.createTable(self.makeCreateStatement(connector, model: model)))
        }
    }
    public func deleteTable<T:SSMappable>() -> SSResult<T> {
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result:self.conn.deleteTable([T.table]))
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
    
    public func table<T:SSMappable>() -> SSTable<T>{
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
    
    public func insert<T:SSMappable>(model:T) -> SSResult<T> {
        let connector = SSConnector(type:.Scan)
        model.dbMap(connector)
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result:self.conn.insert(self.makeInsertStatement(connector,model: model), values:self.getValues(connector)))
        }
    }
    
    public func update<T:SSMappable>(model:T) -> SSResult<T> {
        let connector = SSConnector(type:.Scan)
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
    
    public func query<T:SSMappable>(query:String,params:[AnyObject]) -> SSTable<T>{
        let connector = SSConnector(type: .Map)
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
    
    public func delete<T:SSMappable>(model:T) -> SSResult<T> {
        let connector = SSConnector(type:.Scan)
        model.dbMap(connector)
        guard let theKey = getPrimaryKey(connector)?.value else{
            return SSResult<T>(result: false)
        }
        return executeInTransaction{
            [unowned self] in
            return SSResult<T>(result:self.conn.delete(self.makeDeleteStatement(connector,model: model),values: [theKey]))
        }
    }
    
    public func beginTransaction(){
        conn.beginTransaction()
    }
    public func commit(){
        conn.commit()
    }
    public func rollback(){
        conn.rollback()
    }
    
    private func getPrimaryKey(connector:SSConnector) -> SSScan? {
        for item in connector.scans{
            if item.isPrimaryKey && item.value != nil {
                return item
            }
        }
        return nil
    }
    
    private func makeUpdateStatement<T:SSMappable>(connector:SSConnector, model:T) -> String {
        var columns = String.empty
        let scans = removePrimaryKey(connector)
        let count = scans.count
        scans.enumerate().forEach{
            let separator = count-1 == $0.index ? String.empty : ","+String.whiteSpace
            columns += "\($0.element.name)=?" + separator
        }
        let theKey = getPrimaryKey(connector)!
        return "UPDATE \(T.table) SET \(columns) WHERE \(theKey.name)=?;"
    }
    
    private func makeCreateStatement<T:SSMappable>(connector:SSConnector,model:T) -> String {
        var columns:String = String.empty
        connector.scans.enumerate().forEach{
            let separator = (connector.scans.count-1) == $0.index ? String.empty : ","+String.whiteSpace
            columns += $0.element.createColumnStatement() + separator
        }
        return "CREATE TABLE \(T.table)(\(columns));"
    }
    
    private func makeSelectAllStatement<T:SSMappable>(model:T) -> String {
        return "SELECT * From \(T.table);"
    }
    
    private func makeInsertStatement<T:SSMappable>(connector:SSConnector, model:T) -> String {
        var columns = String.empty
        let count = connector.scans.count{ $0.value != nil }
        connector.scans.select{ $0.value != nil }.enumerate().forEach{
            let separator = count-1 == $0.index ? String.empty : ","+String.whiteSpace
            columns += $0.element.name + separator
        }
        return "INSERT INTO \(T.table)(\(columns)) VALUES(\(makePlaceholderStatement(count)));"
    }
    
    private func makeDeleteStatement<T:SSMappable>(connector:SSConnector,model:T) -> String {
        let theKey = getPrimaryKey(connector)!
        return "DELETE FROM \(T.table) WHERE \(theKey.name)=?;"
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
    
    private func getAllValue(connector:SSConnector) -> [AnyObject] {
        return removePrimaryKey(connector).map{
            if let theValue = $0.value {
                return theValue
            }
            return NSNull()
        }
    }
    
    private func removePrimaryKey(connector:SSConnector) -> [SSScan] {
        var scans = connector.scans
        for scan in scans.enumerate() {
            if scan.element.isPrimaryKey { scans.removeAtIndex(scan.index) }
        }
        return scans
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
            if let theValue = values[name]{
                map.value = theValue
            }
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

public func == (lhs:CLAttr,rhs:CLAttr) -> Bool{
    switch (lhs,rhs) {
    case (.PrimaryKey,.PrimaryKey):
        return true
    case (.AutoIncrement,.AutoIncrement):
        return true
    case (.NotNull,.NotNull):
        return true
    case (.Unique,.Unique):
        return true
    case (.Default,.Default):
        return true
    case (.Check,.Check):
        return true
    default:
        return false
    }
}

infix operator <- {
    precedence 20
    associativity none
}

public func <- <T>(inout lhs:T?,rhs:SSWorker){
    rhs.work(&lhs)
}




