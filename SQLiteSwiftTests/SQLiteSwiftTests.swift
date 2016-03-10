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
    
    func testTable(){
        //Create User Table if User Table is not exist
        let _ = SQLiteConnection(filePath: dbFilePath).deleteTable(User)
        let _ = SQLiteConnection(filePath: dbFilePath).createTable(User)
        let params = [
            ["27","takasi","takayan","1"],
            ["20","hanako","hanatyan","0"],
            ["30","masumi","masu","1"],
        ]
        conn.beginTransaction()
        for param in params {
            conn.insert("INSERT INTO User(age,name,nickname,isMan) VALUES(?,?,?,?);", values: param)
        }
        conn.commit()
        
        let results = SQLiteConnection(filePath: dbFilePath).table(User)
        XCTAssertEqual(results.records.count,params.count)
        
        for result in results.records.enumerate() {
            XCTAssertEqual(Int(params[result.index][0]),result.element.age)
            XCTAssertEqual(params[result.index][1],result.element.name)
            XCTAssertEqual(params[result.index][2],result.element.nickname)
            XCTAssertEqual(Int(params[result.index][3]) != 0,result.element.isMan)
        }
    }
    
    func testUpdate(){
        //Create User Table if User Table is not exist
        let _ = SQLiteConnection(filePath: dbFilePath).deleteTable(User)
        let _ = SQLiteConnection(filePath: dbFilePath).createTable(User)
        let params = [
            ["27","takasi","takayan","1"]
        ]
        conn.beginTransaction()
        for param in params {
            conn.insert("INSERT INTO User(age,name,nickname,isMan) VALUES(?,?,?,?);", values: param)
        }
        conn.commit()
        
        var result = SQLiteConnection(filePath: dbFilePath).table(User)
        var model = result.records[0]
        model.name = "none"
        model.age = 100
        model.isMan = false
        model.nickname = nil
        
        let connection = SQLiteConnection(filePath: dbFilePath)
        connection.isOutput = true
        let result2 = connection.update(model)
        XCTAssertTrue(result2.result)
        
        result = SQLiteConnection(filePath: dbFilePath).table(User)
        
        XCTAssertEqual(result.records.count,1)
        model = result.records[0]
        XCTAssertEqual(model.name!,"none")
        XCTAssertEqual(model.age!,100)
        XCTAssertTrue(model.nickname == nil)
        XCTAssertEqual(model.isMan!,false)
    }
    
    func testQuery(){
        let _ = SQLiteConnection(filePath: dbFilePath).deleteTable(User)
        let _ = SQLiteConnection(filePath: dbFilePath).createTable(User)
        let params = [
            ["21","takasi","takayan","1"],
            ["25","hanako","hanatyan","0"],
            ["30","masumi","masu","1"],
        ]
        conn.beginTransaction()
        for param in params {
            conn.insert("INSERT INTO User(age,name,nickname,isMan) VALUES(?,?,?,?);", values: param)
        }
        conn.commit()
        
        let query = "SELECT name, age FROM User WHERE age>? AND age<?;"
        let values = [21,30]
        let result = SQLiteConnection(filePath: dbFilePath).query(User).exec(query,values)
        
        XCTAssertEqual(result.records.count,1)
        let element = result.records[0]
        XCTAssertEqual(Int(params[1][0]),element.age)
        XCTAssertEqual(params[1][1],element.name)
    }

    
    func testQueryInTransaction(){
        let _ = SQLiteConnection(filePath: dbFilePath).deleteTable(User)
        let _ = SQLiteConnection(filePath: dbFilePath).createTable(User)
        let params = [
            ["21","takasi","takayan","1"],
            ["25","hanako","hanatyan","0"],
            ["30","masumi","masu","1"],
        ]
        conn.beginTransaction()
        for param in params {
            conn.insert("INSERT INTO User(age,name,nickname,isMan) VALUES(?,?,?,?);", values: param)
        }
        conn.commit()
        
        let connect = SQLiteConnection(filePath: dbFilePath)
        let query = "SELECT name, age FROM User WHERE age>? AND age<?;"
        let values = [21,30]
        connect.beginTransaction()
        let result = connect.query(User).exec(query,values)
        
        let user = User()
        user.name = "hoge"
        user.age = 23
        let dmResult = connect.insert(user)
        XCTAssertTrue(dmResult.result)
        let dmResult2 = connect.table(User)
        XCTAssertEqual(dmResult2.records.count,4)
        
        connect.commit()
        
        let dmResult3 = SQLiteConnection(filePath: dbFilePath).table(User)
        XCTAssertEqual(dmResult3.records.count,4)
        
        let element = result.records[0]
        XCTAssertEqual(Int(params[1][0]),element.age)
        XCTAssertEqual(params[1][1],element.name)
    }
    
    func testInsert(){
        let _ = SQLiteConnection(filePath: dbFilePath).deleteTable(User)
        let _ = SQLiteConnection(filePath: dbFilePath).createTable(User)
        
        let user = User()
        user.name = "takashi"
        user.age = 27
        user.nickname = "takayan"
        user.isMan = true
        
        let user2 = User()
        user2.name = "nozomi"
        user2.age = 20
        user2.nickname = "nozomin"
        user2.isMan = false
        
        let users:[User] = [user,user2]
        
        users.enumerate().forEach{
            let result = SQLiteConnection(filePath: dbFilePath).insert($0.element)
            XCTAssertTrue(result.result)
        }
        let results = SQLiteConnection(filePath: dbFilePath).table(User)
        results.records.enumerate().forEach{
            XCTAssertEqual($0.element.name!, users[$0.index].name)
            XCTAssertEqual($0.element.age!, users[$0.index].age)
            XCTAssertEqual($0.element.nickname!, users[$0.index].nickname)
            XCTAssertEqual($0.element.isMan!, users[$0.index].isMan)
        }
    }
    
    func testDelete(){
        //Create User Table if User Table is not exist
        let _ = SQLiteConnection(filePath: dbFilePath).deleteTable(User)
        let _ = SQLiteConnection(filePath: dbFilePath).createTable(User)
        let params = [
            ["27","takasi","takayan","1"],
            ["20","hanako","hanatyan","0"],
            ["30","masumi","masu","1"],
        ]
        conn.beginTransaction()
        for param in params {
            conn.insert("INSERT INTO User(age,name,nickname,isMan) VALUES(?,?,?,?);", values: param)
        }
        conn.commit()
        
        let result = SQLiteConnection(filePath: dbFilePath).table(User)
        let model = result.records[1]
        let connetor = SQLiteConnection(filePath: dbFilePath)
        connetor.isOutput = true
        let result2 = connetor.delete(model)
        XCTAssertTrue(result2.result)
        
        let result3 = SQLiteConnection(filePath: dbFilePath).table(User)
        XCTAssertEqual(result3.records.count, params.count - 1)
        for item in result3.records {
            XCTAssertTrue(item.id != model.id)
        }
    }
    
    func testInsertInTransaction(){
        let _ = SQLiteConnection(filePath: dbFilePath).deleteTable(User)
        let _ = SQLiteConnection(filePath: dbFilePath).createTable(User)
        
        let user = User()
        user.name = "takashi"
        user.age = 27
        user.nickname = "takayan"
        user.isMan = true
        
        let user2 = User()
        user2.name = "nozomi"
        user2.age = 20
        user2.nickname = "nozomin"
        user2.isMan = false
        
        let users:[User] = [user,user2]
        
        let connection = SQLiteConnection(filePath: dbFilePath)
        connection.beginTransaction()
        users.enumerate().forEach{
            let result = connection.insert($0.element)
            XCTAssertTrue(result.result)
        }
        //still uncomitt, so result of select is 0 count
        let tmpResult = connection.table(User)
        XCTAssertEqual(tmpResult.records.count,2)
        
        connection.commit()
        
        let results = SQLiteConnection(filePath: dbFilePath).table(User)
        results.records.enumerate().forEach{
            XCTAssertEqual($0.element.name!, users[$0.index].name)
            XCTAssertEqual($0.element.age!, users[$0.index].age)
            XCTAssertEqual($0.element.nickname!, users[$0.index].nickname)
            XCTAssertEqual($0.element.isMan!, users[$0.index].isMan)
        }
    }
    
    func testCreateTableNotInTransaction() {
        conn.beginTransaction()
        conn.deleteTable(["User"])
        conn.commit()
        
        var result2 = SQLiteConnection(filePath: dbFilePath).isExistTable(User)
        XCTAssertFalse(result2.result)
        
        let result = SQLiteConnection(filePath: dbFilePath).createTable(User)
        XCTAssertTrue(result.result)

        result2 = SQLiteConnection(filePath: dbFilePath).isExistTable(User)
        XCTAssertTrue(result2.result)
    }
    
    func testCreateTableInTransaction() {
        let connector = SQLiteConnection(filePath: dbFilePath);
        
        connector.beginTransaction()
        let result = connector.deleteTable(User)
        XCTAssertTrue(result.result)
        connector.commit()
        
        connector.beginTransaction()
        let result2 = connector.createTable(User)
        XCTAssertTrue(result2.result)
        connector.commit()
        
        conn.beginTransaction()
        XCTAssertTrue(conn.isExistTable(["User"]).result)
        conn.commit()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
            self.testInsertInTransaction()
        }
    }
    
}
