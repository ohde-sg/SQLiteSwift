//
//  SSQuery.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/03/11.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public class SSQuery<T:SSMappable>{
    var exec:(String,[AnyObject]) -> SSTable<T>
    init(exec:(String,[AnyObject])->SSTable<T>){
        self.exec = exec
    }
}
