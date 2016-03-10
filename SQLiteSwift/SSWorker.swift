//
//  SSWorker.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/03/11.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

/// Use for let work to column. e.g) scan column info, mapping value to column variables
public protocol SSWorker{
    var value: AnyObject? { get set }
    func work<T>(inout lhs:T?)
}