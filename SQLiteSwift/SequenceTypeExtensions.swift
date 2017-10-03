//
//  SequenceTypeExtensions.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/27.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

extension Sequence {
    func count(_ judge:(Self.Iterator.Element) -> Bool) -> Int {
        var count = 0
        for item in self {
            if judge(item) { count += 1 }
        }
        return count
    }
    
    func select(_ judge:(Self.Iterator.Element) -> Bool) -> [Self.Iterator.Element] {
        var rtn:[Self.Iterator.Element] = []
        for item in self{
            if judge(item) { rtn.append(item) }
        }
        return rtn
    }
    
    func first(_ judge:(Self.Iterator.Element) -> Bool) -> Self.Iterator.Element? {
        for item in self {
            if judge(item) { return item }
        }
        return nil
    }
}
