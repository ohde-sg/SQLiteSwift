//
//  SSMap.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public class SSMap: SSBase{
    public var value : AnyObject?
}

public func <- <T>(inout lhs:T?,rhs:SSMap) {
    lhs = rhs.value as? T
}
public func <- (inout lhs:Bool?,rhs:SSMap) {
    let val:Int = rhs.value as! Int
    lhs = (val != 0)
}
