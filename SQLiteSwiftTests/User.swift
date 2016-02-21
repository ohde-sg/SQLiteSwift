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
    var table:String = "User"
    var id:Int?
    var name:String?
    var nickname:String?
    var isMan:Bool?
    
    required init(){
        
    }
    
    func dbMap(connector:SSConnector){
        id       <- connector["id",CLAttr.PrimaryKey,CLAttr.AutoIncrement]
        name     <- connector["name",CLAttr.Unique]
        nickname <- connector["nickname",CLAttr.Default("None")]
        isMan    <- connector["isMan"]
    }
}