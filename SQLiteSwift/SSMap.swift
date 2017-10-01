//
//  SSMap.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

open class SSMap: SSWorker{
    open var value : AnyObject?
    open func work<T>(_ lhs: inout T?){
        
        guard let theValue = self.value else {
            return
        }
        
        if theValue is NSNull {
           return
        }
        
        if type(of: lhs) == Optional<Bool>.self {
            let val = theValue as? Int
            lhs = (val != 0) as? T
        }else if type(of: lhs) == Optional<String>.self {
            lhs = String(describing: theValue) as? T
        }else{
            lhs = self.value as? T
        }
    }
}

