//
//  SSScan.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public class SSScan: SSWorker{
    var attrs:[CLAttr]
    var type: CLType?
    public var value:AnyObject?
    var name:String
    init(_ name:String, attrs:[CLAttr]){
        self.name = name
        self.attrs = attrs
    }
    func createColumnStatement() -> String{
        var statement = name
        switch type! {
        case .CL_Integer:
            statement += String.whiteSpace + "INTEGER"
        case .CL_Text:
            statement += String.whiteSpace + "TEXT"
        case .CL_Real:
            statement += String.whiteSpace + "REAL"
        }
        for item in attrs {
            switch item {
            case .AutoIncrement:
                statement += String.whiteSpace + "AUTOINCREMENT"
            case .PrimaryKey:
                statement += String.whiteSpace + "PRIMARY KEY"
            case .NotNull:
                statement += String.whiteSpace + "NOT NULL"
            case .Unique:
                statement += String.whiteSpace + "UNIQUE"
            case .Default(let value):
                statement += String.whiteSpace + "DEFAULT \(value)"
            case .Check(let value):
                statement += String.whiteSpace + "CHECK(\(value))"
            }
        }
        return statement
    }
    
    public func work<T>(inout lhs: T?) {
        if lhs is Int? {
            self.type = CLType.CL_Integer
            self.value = lhs as? AnyObject
        }
        if lhs is Bool? {
            self.type = CLType.CL_Integer
            if let theLhs = lhs {
                self.value = theLhs as! Bool ? 1 : 0
            }
            return
        }
        //Real
        if lhs is Double? || lhs is Float?{
            self.type = CLType.CL_Real
        }
        //Text
        if lhs is String? {
            self.type = CLType.CL_Text
        }
        
        if let theLhs = lhs {
            self.value = theLhs as? AnyObject
        }
    }
    
    var isPrimaryKey : Bool {
        for attr in self.attrs {
            if attr == .PrimaryKey {
                return true
            }
        }
        return false
    }
}

