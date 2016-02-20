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
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSample() {
//        let scan = SQLiteConnection<User>(filePath: dbFilePath).scan()
//        for item in scan.scans {
//            print(item.name,item.type,item.attrs)
//        }
        let map = SQLiteConnection<User>(filePath: dbFilePath).mapping()
        print(map.id,map.name,map.nickname,map.isMan)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
