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
    public func work<T>(inout lhs: T?) {
        if lhs is Bool {
            let val:Int = self.value as! Int
            lhs = (val != 0) as? T
        }else{
            lhs = self.value as? T
        }
    }
}

