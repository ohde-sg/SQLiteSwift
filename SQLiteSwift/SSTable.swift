//
//  SSTable.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public class SSTable<T:SSMappable> {
    public var records:[T] = []
}