//
//  Enums.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/03/11.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation

public enum SSType {
    case Scan
    case Map
}

public enum CLType{
    case CL_Integer
    case CL_Text
    case CL_Real
    //    case CL_BLOB
}

public enum CLAttr{
    case PrimaryKey
    case AutoIncrement
    case NotNull
    case Unique
    case Default(AnyObject)
    case Check(String)
}
