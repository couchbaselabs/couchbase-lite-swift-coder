# CouchbaseLiteSwiftCoder

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

An experiment using Swift's Encoder/Decoder to build data model for Couchbase Lite Swift.

## Requirements
* CouchbaseLiteSwift 2.8+

## Platforms
* iOS (9.0+) and macOS (10.11+)
* XCode 12+

## Encoder and Decoder API

###CBLEncoder

```swift
func encode<T: CBLEncodable>(_ value: T) throws -> MutableDocument

func encode<T: CBLEncodable>(_ value: T, for documentID: String) throws -> MutableDocument

func encode<T: CBLEncodable>(_ value: T, into document: MutableDocument) throws -> MutableDocument
```

###CBLDecoder

```swift
func decode<T: CBLDecodable>(_ type: T.Type, from document: Document) throws -> T

func decode<T: CBLDecodable>(_ type: T.Type, from result: Result) throws -> T
```

###CBLCodable

```swift
public protocol CBLEncodable: Encodable { }

protocol CBLDecodable: Decodable { }

typealias CBLCodable = CBLEncodable & CBLDecodable
```

## Couchbase Lite Extension API

###DocumentCodable

```Swift
public protocol DocumentฺEncodable: CBLEncodable {
    var document: MutableDocument? { get set }
}

public protocol DocumentDecodable: CBLDecodable {
    mutating func decoded(for document: Document)
}

public protocol DocumentCodable: DocumentฺEncodable, DocumentDecodable { }
```

###Database
```Swift
func document<T: DocumentDecodable>(withID id: String, as type: T.Type) throws -> T?

func saveDocument<T: DocumentฺEncodable>(_ encodable: inout T, forID id: String? = nil) throws
```

###Document
```Swift
func decode<T: DocumentDecodable>(_ type: T.Type) throws -> T
```

###Result
```Swift
func decode<T: CBLDecodable>(_ type: T.Type) throws -> T
```

###ResultSet
```Swift
func decode<T: CBLDecodable>(_ type: T.Type) throws -> [T]
```

## Model Supported Data Types
* String
* Numbers
* Boolean
* Date
* Blob

## Future
* Support More Data Types
* Support Relationship

## Example

###Model

```Swift
struct Student: DocumentCodable {
	// Required by DocumentCodable
	var document: MutableDocument?
	
	var name: String
	var dob: Date?
	var address: Address?
	var contacts: [Person]?
	
	// Required for ignoring the document property
	enum CodingKeys: String, CodingKey {
        case name
        case dob
        case address
        case contacts
    }
}

struct Person: CBLCodable {
    var name: String
    var phone: String
}

struct Address: CBLCodable {
    let street: String
}
```
When using DocumentCodable, the document property is required so that the model object could enclose its associated version of the document which the model object is encoded into or which the model object is decoded from.

###Save Model Object

```Swift
// Create Student Object
var student = Student(name: "Daniel")
student.dob = dateObject
student.address = Address(street: "1 Main Street")
student.contacts = [Person(name: "James", phone: "650-123-4567")]

// Save
try student.save(into: self.db, forID: "student1")

```

###Get Model Object
```Swift
let student = try self.db.document(withID: "student1", as: Student.self)
```

###Query Results
```Swift
// Query
let results = try QueryBuilder
            .select(SelectResult.property("name"),
                    SelectResult.property("address"),
                    SelectResult.property("dob"),
                    SelectResult.property("contacts"),
                    SelectResult.property("photo"))
            .from(DataSource.database(self.db))
            .execute()

// Decode
let students = try results.decode(Student.self)
```

