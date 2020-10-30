# CouchbaseLiteSwiftCoder

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

An experiment using Swift's Encoder/Decoder to build data model for Couchbase Lite Swift.

## Requirements
* CouchbaseLiteSwift 2.8+

## Platforms
* iOS (9.0+) and macOS (10.11+)
* XCode 12+

## Encoder and Decoder API

### CBLEncoder

```swift
func encode<T: CBLEncodable>(_ value: T) throws -> MutableDocument

func encode<T: CBLEncodable>(_ value: T, for documentID: String) throws -> MutableDocument

func encode<T: CBLEncodable>(_ value: T, into document: MutableDocument) throws -> MutableDocument
```

### CBLDecoder

```swift
func decode<T: CBLDecodable>(_ type: T.Type, from document: Document) throws -> T

func decode<T: CBLDecodable>(_ type: T.Type, from result: Result) throws -> T
```

### CBLCodable

```swift
public protocol CBLEncodable: Encodable { }

protocol CBLDecodable: Decodable { }

typealias CBLCodable = CBLEncodable & CBLDecodable
```

## Couchbase Lite Extension API

### DocumentCodable

```Swift
public protocol DocumentฺEncodable: CBLEncodable {
    var document: MutableDocument! { get set }
}

public protocol DocumentDecodable: CBLDecodable {
    mutating func decoded(for document: Document)
}

public protocol DocumentCodable: DocumentฺEncodable, DocumentDecodable { }
```

When implementing DocumentCodable, the document property is required so that the model object could enclose its associated version of the document, which the model object is encoded into or which the model object decodes from.

### DocumentCodable Extension
```Swift
mutating func save(into database: Database) throws
```

### Database
```Swift
func document<T: DocumentDecodable>(withID id: String, as type: T.Type) throws -> T?

func saveDocument<T: DocumentฺEncodable>(_ encodable: T) throws
```

### Document
```Swift
func decode<T: DocumentDecodable>(_ type: T.Type) throws -> T
```

### Result
```Swift
func decode<T: CBLDecodable>(_ type: T.Type) throws -> T
```

### ResultSet
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

### Use CBLEncoder and CBLDecoder

```Swift
struct Student: CBLCodable {
    var name: String
    var grade: Int
}

// Encode
let student1 = Student(name: "James", grade: 1)
let encoder = CBLEncoder()
let doc1 = try encoder.encode(student1)

// Decode
let doc2 = try self.db.document(withID: "student2")
let decoder = CBLDecoder()
let student2 = try decoder.decode(Person.self, from: doc2) 
```

### Define Data Model using DocumentCodable
```Swift
struct Employee: DocumentCodable {
    // Required
    var document: MutableDocument!
    
    // Model Properties
    var name: String
    var dob: Date?
    var address: Address?
    var contacts: [Person]?
	
    // Coding Keys
    enum CodingKeys: String, CodingKey {
        case name
        case dob
        case address
        case contacts
    }
    
    // Constructor
    init(id: String? = nil, name: String) {
        self.document = MutableDocument(id: id)
        self.name = name
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

**Note:** The CodkingKeys is currently required for ignoring the document property from being encoded or decoded.

### Save DocumentCodable Model Object

```Swift
// Create an employee object
var employee = Employee(name: "Jimmy")
employee.dob = dob
employee.address = Address(street: "1 Main Street")
employee.contacts = [Person(name: "Jackson", phone: "650-123-4567")]

// Save
try employee(into: self.db)
```

### Get DocumentCodable Model Object
```Swift
let employee = try self.db.document(withID: "emp1", as: Employee.self)
```

### Decode Query Results
```Swift
// Query
let results = try QueryBuilder
	.select(
		SelectResult.property("name"),
		SelectResult.property("address"),
		SelectResult.property("dob"),
		SelectResult.property("contacts"),
		SelectResult.property("photo"))
	.from(DataSource.database(self.db))
	.execute()

// Decode
let employees = try results.decode(Employee.self)
```

