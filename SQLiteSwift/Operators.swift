//
//  Operators.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/03/11.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public func == (lhs:CLAttr,rhs:CLAttr) -> Bool{
    switch (lhs,rhs) {
    case (.PrimaryKey,.PrimaryKey):
        return true
    case (.AutoIncrement,.AutoIncrement):
        return true
    case (.NotNull,.NotNull):
        return true
    case (.Unique,.Unique):
        return true
    case (.Default,.Default):
        return true
    case (.Check,.Check):
        return true
    default:
        return false
    }
}

infix operator <- {
precedence 20
associativity none
}

public func <- <T>(inout lhs:T?,rhs:SSWorker){
    rhs.work(&lhs)
}
