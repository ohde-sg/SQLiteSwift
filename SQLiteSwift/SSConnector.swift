//
//  SSConnector.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/03/11.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public class SSConnector {
    var values:[String:AnyObject?]=[:]
    var scans:[SSScan] = []
    var type:SSType
    public init(type:SSType){
        self.type = type
    }
    public subscript (name:String,attrs:CLAttr...) -> SSWorker{
        switch self.type {
        case .Map:  // return map worker
            let map = SSMap()
            if let theValue = values[name]{
                map.value = theValue
            }
            return map
        case .Scan: // return scan worker
            let scan = SSScan(name,attrs: attrs)
            scans.append(scan)
            return scan
        }
    }
}