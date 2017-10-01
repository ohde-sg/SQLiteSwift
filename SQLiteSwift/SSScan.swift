//
//  SSScan.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

open class SSScan: SSWorker{
    var attrs:[CLAttr]
    var type: CLType?
    open var value:AnyObject?
    var name:String
    init(_ name:String, attrs:[CLAttr]){
        self.name = name
        self.attrs = attrs
    }
    func createColumnStatement() -> String{
        var statement = name
        switch type! {
        case .cl_Integer:
            statement += String.whiteSpace + "INTEGER"
        case .cl_Text:
            statement += String.whiteSpace + "TEXT"
        case .cl_Real:
            statement += String.whiteSpace + "REAL"
        }
        for item in attrs {
            switch item {
            case .autoIncrement:
                statement += String.whiteSpace + "AUTOINCREMENT"
            case .primaryKey:
                statement += String.whiteSpace + "PRIMARY KEY"
            case .notNull:
                statement += String.whiteSpace + "NOT NULL"
            case .unique:
                statement += String.whiteSpace + "UNIQUE"
            case .default(let value):
                statement += String.whiteSpace + "DEFAULT \(value)"
            case .check(let value):
                statement += String.whiteSpace + "CHECK(\(value))"
            }
        }
        return statement
    }
    
    open func work<T>(_ lhs: inout T?) {
        if type(of: lhs) == Optional<Int>.self {
            self.type = CLType.cl_Integer
            self.value = lhs as AnyObject
        }
        if type(of: lhs) == Optional<Bool>.self {
            self.type = CLType.cl_Integer
            if let theLhs = lhs {
                self.value = (theLhs as! Bool ? 1 : 0 ) as AnyObject
            }
            return
        }
        //Real
        if type(of: lhs) == Optional<Double>.self || type(of: lhs) == Optional<Float>.self {
            self.type = CLType.cl_Real
        }
        //Text
        if type(of: lhs) == Optional<String>.self {
            self.type = CLType.cl_Text
        }
        
        if let theLhs = lhs {
            self.value = theLhs as AnyObject
        }
    }
    
    var isPrimaryKey : Bool {
        for attr in self.attrs {
            if attr == .primaryKey {
                return true
            }
        }
        return false
    }
}

