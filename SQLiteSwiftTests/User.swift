//
//  User.swift
//  SQLiteSwift
//
//  Created by 大出喜之 on 2016/02/21.
//  Copyright © 2016年 yoshiyuki ohde. All rights reserved.
//

import Foundation
import SQLiteSwift

class User: SSMappable {
    static var table:String = "User"
    var id:Int?
    var name:String?
    var age:Int?
    var nickname:String?
    var isMan:Bool?
    
    required init(){
        
    }
    
    func dbMap(connector:SSConnector){
        id       <- connector["id", .PrimaryKey, .AutoIncrement, .NotNull]
        name     <- connector["name", .Unique]
        age      <- connector["age", .Check("age>0")]
        nickname <- connector["nickname", .Default("None")]
        isMan    <- connector["isMan"]
    }
}