//
//  SQLiteSwiftTests.swift
//  SQLiteSwiftTests
//
//  Created by 大出喜之 on 2016/02/15.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import XCTest
@testable import SQLiteSwift

class SQLiteSwiftTests: XCTestCase {
    let dbFile:String = "sqliteswift.db"
    let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    private var dbFilePath: String {
        get{
            return self.dir + "/" + self.dbFile
        }
    }
    var _conn :SQLite?
    private var conn: SQLite{
        if _conn == nil {
            _conn = SQLite(self.dbFilePath)
            return _conn!
        }
        return _conn!
    }
    
    override func setUp() {
        print(dbFilePath)
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSample() {
        let connector = SQLiteConnection(filePath: dbFilePath)
        let scan:(SSConnector,User) = connector.scan()
        var values = ["id":(CLType.CL_Integer,[CLAttr.PrimaryKey,CLAttr.AutoIncrement, .NotNull]),
            "name":(CLType.CL_Text,[CLAttr.Unique]),
            "age" : (CLType.CL_Integer,[CLAttr.Check("age>0")]),
            "nickname":(CLType.CL_Text,[CLAttr.Default("None")]),
            "isMan":(CLType.CL_Integer,[]),]
        for item in scan.0.scans {
            //Assert type of Column
            XCTAssertEqual(item.type!, values[item.name]!.0)
            //Assert count of attributes
            XCTAssertEqual(values[item.name]!.1.count,item.attrs.count)
            //Assert type of attributes
            for (index,value) in  values[item.name]!.1.enumerate() {
                XCTAssertEqual(String(item.attrs[index]),String(value))
            }
        }
        let map:User = SQLiteConnection(filePath: dbFilePath).mapping()
        print(map.id,map.name,map.nickname,map.isMan)
    }
    
    func testTable(){
        
    }
    
    func testCreateTableNotInTransaction() {
        conn.beginTransaction()
        conn.deleteTable(["User"])
        conn.commit()
        
        let result:(Bool,User) = SQLiteConnection(filePath: dbFilePath).createTable()
        XCTAssertTrue(result.0)
        
        conn.beginTransaction()
        XCTAssertTrue(conn.isExistTable(["User"]).result)
        conn.commit()
    }
    
    func testCreateTableInTransaction() {
        let connector = SQLiteConnection(filePath: dbFilePath);
        
        connector.beginTransaction()
        let result:(Bool,User) = connector.deleteTable()
        XCTAssertTrue(result.0)
        connector.commit()
        
        connector.beginTransaction()
        let result2:(Bool,User) = connector.createTable()
        XCTAssertTrue(result2.0)
        connector.commit()
        
        conn.beginTransaction()
        XCTAssertTrue(conn.isExistTable(["User"]).result)
        conn.commit()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
