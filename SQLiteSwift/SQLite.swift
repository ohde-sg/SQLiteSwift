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
    static fileprivate var conn: SQLite?
    fileprivate let dbFilePath: String
    fileprivate var _db:FMDatabase?
    fileprivate var db: FMDatabase {
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
    func createTable(_ sql:String) -> Bool {
        return executeUpdate(sql,nil)
    }
    
    func deleteTable(_ tables:[String]) -> Bool {
        let sql = "DROP TABLE IF EXISTS"
        var result:Bool = true
        tables.forEach{
            if !executeUpdate(sql + " \($0);", nil) {
                result = false
            }
        }
        return result
    }
    
    func insert(_ sql:String,values:[AnyObject]!) -> Bool {
        return executeUpdate(sql,values)
    }
    
    func update(_ sql:String,values:[AnyObject]!) -> Bool {
        return executeUpdate(sql,values)
    }
    
    func delete(_ sql:String,values:[AnyObject]!) -> Bool {
        return executeUpdate(sql, values)
    }
    
    fileprivate func executeUpdate(_ sql:String, _ values: [AnyObject]!) -> Bool{
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
    
    fileprivate func executeQuery(_ sql:String, values:[AnyObject]!) -> FMResultSet? {
        if isOutput {
            print("Query: \(sql)")
        }
        return try? db.executeQuery(sql, values: values)
    }
    
    func beginTransaction(){
        if !db.isInTransaction {
            db.open()
            db.beginTransaction()
        }
    }
    
    var inTransaction:Bool {
        return db.isInTransaction
    }
    
    func commit() {
        if db.isInTransaction {
            db.commit()
            db.close()
        }
    }
    
    func rollback(){
        if db.isInTransaction {
            db.rollback()
        }
    }
    
    /// Return whether DBFile is exist
    /// - returns: true on exist, false on not exist
    func isExistDBFile() -> Bool {
        let fileManager: FileManager = FileManager.default
        return fileManager.fileExists(atPath: self.dbFilePath)
    }
    
    /// Return whether Tables are exist
    /// - parameter table names string array
    /// - returns: false & table array on not exist , true & blank array on all tables exist
    func isExistTable(_ tables:[String]) -> (result:Bool,tables:[String]?) {
        let sql = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?;"
        var rtnBl:Bool = true
        var noExistTables:[String] = []
        for table in tables {
            let result = executeQuery(sql, values: [table as AnyObject])
            defer { result?.close() }
            guard let theResult = result else {
                return (false,nil)
            }
            theResult.next()
            if theResult.int(forColumnIndex: 0) == 0 {
                rtnBl = false
                noExistTables.append(table)
            }
        }
        return (!rtnBl && noExistTables.count>0) ? (false,noExistTables) : (rtnBl,nil)
    }
    
    func select(_ sql:String,values:[AnyObject]!) -> [[String:AnyObject]] {
        let result = executeQuery(sql, values: values)
        defer { result?.close() }
        var rtn:[[String:AnyObject]] = []
        guard let theResult = result else{
            return rtn
        }
        while  theResult.next() {
            var dict:[String:AnyObject] = [:]
            if let resultDictionary = theResult.resultDictionary {
                for(key,value) in resultDictionary {
                    let theKey = key as! String
                    dict[theKey] = value as AnyObject
                }
                rtn.append(dict)
            }
        }
        return rtn
    }
}



