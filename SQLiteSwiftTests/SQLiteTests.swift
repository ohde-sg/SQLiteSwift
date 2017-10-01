//
//  SQLiteSwiftTests.swift
//  SQLiteSwiftTests
//
//  Created by 大出喜之 on 2016/02/15.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import XCTest
@testable import SQLiteSwift

class SQLiteTests: XCTestCase {
    let dbFile:String = "sqliteswift.db"
    let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    fileprivate var dbFilePath: String {
        get{
            return self.dir + "/" + self.dbFile
        }
    }
    
    var _conn :SQLite?
    fileprivate var conn: SQLite{
        if _conn == nil {
            _conn = SQLite(self.dbFilePath)
            return _conn!
        }
        return _conn!
    }
    
    override func setUp() {
        super.setUp()
        print(self.dbFilePath)
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateTableAndExistTable() {
        let tables = ["memoA","memoB","memoC"]
        conn.beginTransaction()
        conn.deleteTable(tables)
        XCTAssertTrue(!conn.isExistTable(tables).result)
        tables.forEach{
            conn.createTable("CREATE TABLE \($0)(id INTEGER PRIMARY KEY AUTOINCREMENT, title text);")
        }
        XCTAssertTrue(conn.isExistTable(tables).result)
        conn.commit()
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testConnInsertAndSelect(){
        let params = [
            ["today","nothing to do"],
            ["tomorrow","nothing to execute"],
            ["dayaftertomorrow","nothing to work..."]
        ]
        conn.beginTransaction()
        conn.deleteTable(["Sample"])
        conn.createTable("CREATE TABLE Sample(id INTEGER PRIMARY KEY AUTOINCREMENT, title text, descri text);")
        
        params.forEach{
            conn.insert("INSERT INTO Sample(title,descri) VALUES(?,?);", values: [$0[0],$0[1]])
        }
        
        let result = conn.select("SELECT * FROM Sample;",values: nil)
        result.enumerate().forEach{
            XCTAssertEqual($0.element["title"] as? String, params[$0.index][0])
            XCTAssertEqual($0.element["descri"] as? String, params[$0.index][1])
        }
        conn.commit()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
