//
//  SSScan.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public class SSScan: SSBase{
    var attrs:[CLAttr]
    var type: CLType?
    public var value:AnyObject?
    var name:String
    init(_ name:String, attrs:[CLAttr]){
        self.name = name
        self.attrs = attrs
    }
}

public func <- <T> (inout lhs:T?,rhs:SSScan) {
    //Integer
    if lhs is Int? {
        rhs.type = CLType.CL_Integer
        rhs.value = lhs as? AnyObject
    }
    if lhs is Bool? {
        rhs.type = CLType.CL_Integer
        if let theLhs = lhs {
            rhs.value = theLhs as! Bool ? 1 : 0
        }
        return
    }
    //Real
    if lhs is Double? || lhs is Float?{
        rhs.type = CLType.CL_Real
    }
    //Text
    if lhs is String? {
        rhs.type = CLType.CL_Text
    }
    
    if let theLhs = lhs {
        rhs.value = theLhs as? AnyObject
    }
}
