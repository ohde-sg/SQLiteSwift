# SQLiteSwift
SQLiteSwift is a library written in Swift that makes it easy for you to deal with sqlite

[![CocoaPods](https://img.shields.io/cocoapods/v/SQLiteSwift.svg)](https://github.com/ohde-sg/SQLiteSwift)
## CocoaPods
~~~
platform :ios, '8.0'
use_frameworks!

target 'XXXX' do
  pod 'SQLiteSwift'
end
~~~

## How to use
### Step 1
* Make a Model
  ~~~swift
  class User: SSMappable {
    static var table:String = "User" // Table Name
    var id:Int?                      // INTEGER Column
    var name:String?                 // TEXT Collumn
    var age:Int?
    var nickname:String?
    var isMan:Bool?                  // INTEGER Column

    required init(){
    }

    func dbMap(connector:SSConnector){
        // id column primarykey, autoincrement, notnull attribute
        id       <- connector["id", .PrimaryKey, .AutoIncrement, .NotNull]
        // name column unique attribute
        name     <- connector["name", .Unique]
        // age column check attribute
        age      <- connector["age", .Check("age>0")]
        // nickname column default attribute
        nickname <- connector["nickname", .Default("None")]
        // isMan column auto convert INTEGER(SQLite) <=> Bool(Swift)
        isMan    <- connector["isMan"]
    }
}
  ~~~

### Step2
* CREATE TABLE
  ~~~swift
    let createTable:SSResult<User> = SQLiteConnection(filePath: dbFilePath).createTable() //make 'User' Table
    if createTable.result {
      print("correct!! make a table")
    }else {
      print("failed to make a table")
    }
  ~~~

* INSERT
  ~~~swift
  let user = User()
  user.name = "takashi"
  user.age = 27
  user.nickname = "takayan"
  user.isMan = true

  let insert:SSResult<User> = SQLiteConnection(filePath: dbFilePath).insert(user) // insert user row

  ~~~

* SELECT
  ~~~swift
  let table:SSTable<User> = SQLiteConnection(filePath: dbFilePath).table() // select User table
  for user in table.records {
    print(user.name,user.age,user.nickname, user.isMan)
  }
  ~~~

* UPDATE
  ~~~swift
  let table:SSTable<User> = SQLiteConnection(filePath: dbFilePath).table()
  let model = table.records[0]
  model.age = 30
  model.isMan = false
  let update:SSResult<User> = SQLiteConnection(filePath: dbFilePath).insert(user) // update user row
  ~~~

* DELETE
  ~~~swift
  let table:SSResult<User> = SQLiteConnection(filePath: dbFilePath).table()
  let model = table.records[0]
  let delete:SSResult<User> = SQLiteConnection(filePath: dbFilePath).delete(model) // delete user row
  ~~~

* IsExistTable
  ~~~swift
  let isExistTable:SSResult<User> = SQLiteConnection(filePath: dbFilePath).isExistTable() // is Exist User table
  if isExistTable.result {
    print("Table is exist")
  }
  ~~~

* DELETE TABLE
  ~~~swift
  let deleteTable:SSResult<User> = SQLiteConnection(filePath: dbFilePath).deleteTable() // delete User table
  if deleteTable.result {
    print("delete table complete!!")
  }
  ~~~

* Query
  ~~~swift
  let query = "SELECT name, age FROM User WHERE age>? AND age<?;"
  let values = [21,30]
  let result:SSTable<User> = SQLiteConnection(filePath: dbFilePath).query(query, params: values)
  ~~~

### More

* Transaction Commit

  ~~~swift
  let connect = SQLiteConnection(filePath: dbFilePath)
  connect.beginTransaction()
  // INSERT,DELETE,UPDATE using connect
  connect.commit()
  ~~~
