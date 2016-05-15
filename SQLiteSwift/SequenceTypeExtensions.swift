//
//  SequenceTypeExtensions.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/27.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

extension SequenceType {
    func count(judge:(Self.Generator.Element) -> Bool) -> Int {
        var count = 0
        for item in self {
            if judge(item) { count += 1 }
        }
        return count
    }
    
    func select(judge:(Self.Generator.Element) -> Bool) -> [Self.Generator.Element] {
        var rtn:[Self.Generator.Element] = []
        for item in self{
            if judge(item) { rtn.append(item) }
        }
        return rtn
    }
    
    func first(judge:(Self.Generator.Element) -> Bool) -> Self.Generator.Element? {
        for item in self {
            if judge(item) { return item }
        }
        return nil
    }
}