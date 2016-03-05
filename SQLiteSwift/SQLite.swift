//
//  SQLiteConnection.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/15.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation
import FMDB

class SQLite {
    static private var conn: SQLite?
    private let dbFilePath: String
    private var _db:FMDatabase?
    private var db: FMDatabase {
        get {
            if let tmpDb = _db {
                return tmpDb
            }else{
                _db = FMDatabase(path: dbFilePath)
                return _db!
            }
        }
    }
    var isOutput:Bool = false
    init(_ filePath:String){
        self.dbFilePath = filePath
    }
    
    /// Create Table according to sql parameter
    /// - parameter sql: sql statement
    /// - returns: true on Success, false on Failure
    func createTable(sql:String) -> Bool {
        return executeUpdate(sql,nil)
    }
    
    func deleteTable(tables:[String]) -> Bool {
        let sql = "DROP TABLE IF EXISTS"
        var result:Bool = true
        tables.forEach{
            if !executeUpdate(sql + " \($0);", nil) {
                result = false
            }
        }
        return result
    }
    
    func insert(sql:String,values:[AnyObject]!) -> Bool {
        return executeUpdate(sql,values)
    }
    
    func update(sql:String,values:[AnyObject]!) -> Bool {
        return executeUpdate(sql,values)
    }
    
    func delete(sql:String,values:[AnyObject]!) -> Bool {
        return executeUpdate(sql, values)
    }
    
    private func executeUpdate(sql:String, _ values: [AnyObject]!) -> Bool{
        do {
            try db.executeUpdate(sql, values: values)
            if isOutput {
                print("Query: \(sql)")
            }
            return true
        } catch {
            db.rollback()
            return false;
        }
    }
    
    private func executeQuery(sql:String, values:[AnyObject]!) -> FMResultSet? {
        if isOutput {
            print("Query: \(sql)")
        }
        return try? db.executeQuery(sql, values: values)
    }
    
    func beginTransaction(){
        if !db.inTransaction() {
            db.open()
            db.beginTransaction()
        }
    }
    
    var inTransaction:Bool {
        return db.inTransaction()
    }
    
    func commit() {
        if db.inTransaction() {
            db.commit()
            db.close()
        }
    }
    
    func rollback(){
        if db.inTransaction() {
            db.rollback()
        }
    }
    
    /// Return whether DBFile is exist
    /// - returns: true on exist, false on not exist
    func isExistDBFile() -> Bool {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(self.dbFilePath)
    }
    
    /// Return whether Tables are exist
    /// - parameter table names string array
    /// - returns: false & table array on not exist , true & blank array on all tables exist
    func isExistTable(tables:[String]) -> (result:Bool,tables:[String]?) {
        let sql = "select count(*) from sqlite_master where type='table' and name=?;"
        var rtnBl:Bool = true
        var noExistTables:[String] = []
        for table in tables {
            let result = executeQuery(sql, values: [table])
            defer { result?.close() }
            guard let theResult = result else {
                return (false,nil)
            }
            theResult.next()
            if theResult.intForColumnIndex(0) == 0 {
                rtnBl = false
                noExistTables.append(table)
            }
        }
        return (!rtnBl && noExistTables.count>0) ? (false,noExistTables) : (rtnBl,nil)
    }
    
    func select(sql:String,values:[AnyObject]!) -> [[String:AnyObject]] {
        let result = executeQuery(sql, values: values)
        defer { result?.close() }
        var rtn:[[String:AnyObject]] = []
        guard let theResult = result else{
            return rtn
        }
        while  theResult.next() {
            var dict:[String:AnyObject] = [:]
            for(key,value) in theResult.resultDictionary() {
                let theKey = key as! String
                dict[theKey] = value
            }
            rtn.append(dict)
        }
        return rtn
    }
}



