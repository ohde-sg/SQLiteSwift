//
//  SSMap.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public class SSMap: SSWorker{
    public var value : AnyObject?
    public func work<T>(inout lhs: T?){
        
        guard let theValue = self.value else {
            return
        }
        
        if theValue is NSNull {
           return
        }
        
        if lhs.dynamicType == Optional<Bool>.self {
            let val = theValue as? Int
            lhs = (val != 0) as? T
        }else if lhs.dynamicType == Optional<String>.self {
            lhs = String(theValue) as? T
        }else{
            lhs = self.value as? T
        }
    }
}

