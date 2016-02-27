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
    
    func executeUpdate(sql:String, _ values: [AnyObject]!) -> Bool{
        do {
            try db.executeUpdate(sql, values: values)
            return true
        } catch {
            db.rollback()
            return false;
        }
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
        do {
            for table in tables {
                let result: FMResultSet = try db.executeQuery(sql, values: [table])
                defer { result.close() }
                result.next()
                if result.intForColumnIndex(0) == 0 {
                    rtnBl = false
                    noExistTables.append(table)
                }
                result.close()
            }
        }catch{
            return (false,nil)
        }
        return (!rtnBl && noExistTables.count>0) ? (false,noExistTables) : (rtnBl,nil)
    }
    
    func select(sql:String,values:[AnyObject]!) -> [[String:AnyObject]] {
        let result = try? db.executeQuery(sql, values: values)
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