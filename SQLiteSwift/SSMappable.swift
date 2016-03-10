//
//  SSMappable.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/03/11.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public protocol SSMappable {
    static var table:String { get }
    func dbMap(connector:SSConnector)
    init()
}