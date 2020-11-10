# CouchbaseLiteSwiftCoder

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

An experiment using Swift's Encoder/Decoder to develop data model for Couchbase Lite Swift.

## Requirements
* CouchbaseLiteSwift 2.8+

## Platforms
* iOS (9.0+) and macOS (10.11+)
* XCode 12+

## Supported Data Types
* String
* Numbers
* Boolean
* Date
* Data
* Blob
* CBLCodable (CBLEncodable and CBLDecodable)
* Array of the types above

## Future Features
* Support More Data Types
* Support Document Relationship

## Installation

### Swift Package Manager

```Swift
dependencies: [
    .package(url: "https://github.com/couchbaselabs/couchbase-lite-swift-coder.git")
]
```
## Usage

### Import Modules
```
import CouchbaseLiteSwift
import CouchbaseLiteSwiftCoder
```

There are two ways of using CouchbaseLiteSwiftCoder.

### #1: Use CBLEncoder and CBLDecoder

CouchbaseLiteSwiftCoder provides CBLEncoder and CBLDecoder class for encoding model objects to Couchbase Lite's MutableDocument objects that can be used to save into the database and for encoding model objects from Couchbase Lite's Document objects respectively.

When definding the model struct or class, there are three protocols that can be used: `CBLEncodable` for encoding only, `CBLDecodable` or decoding only, and `CBLCodable` for both encoding and decoding. 

#### Example

```Swift
// Define Student model:
struct Student: CBLCodable {
    var name: String
    var grade: Int
}

// Encode a model object to a MutableDocument:
let student1 = Student(name: "James", grade: 1)
let encoder = CBLEncoder()
let doc1 = try encoder.encode(student1)

// Decode a model object from a Document object:
let doc2 = try self.db.document(withID: "student2")
let decoder = CBLDecoder()
let student2 = try decoder.decode(Person.self, from: doc2) 
```
When using the CBLEncoder or CBLDecoder, after the model object is encoded or decoded, the model object is independent from its companion MutableDocument or Document object. Application code takes responsibility to manage the relationship between the model and the document object.

### #2: Use DocumentCodable

As we would want to associate the model object and its document object from which the model object is deocded so that the model object will have the right version of the document to be encoded into when saving the model object into the database. A better way to define the model struct or class is to implement `DocumentCodable` protocol (there is also `DocumentEncodable` and `DocumentDecoable` protocol only for encoding and decoding respectively).

When implementing `DocumentCodable`, an additional `document` property of `MutableDocument` type is required. It's important to note that the `document` property is not a part of the properties to be encoded or decoded. In order to ignore the `document` property from being encoded and decoded, the CodingKeys enum needs to be defined to list all of the encoding/decoding keys.   

In additon to the `DocumentCodable` protocol, a set of extensions method to Couchbase Lite's Database and Document API has been defined to allow the model objects to be easily retrived from the database or saved into the database.  

#### Example

#### Defining Model
```Swift
struct Employee: DocumentCodable {
    // Required
    var document: MutableDocument!
    
    // Model Properties
    var name: String
    var dob: Date?
    var address: Address?
    var contacts: [Person]?
	
    // Required Coding Keys for ignoring document property
    enum CodingKeys: String, CodingKey {
        case name
        case dob
        case address
        case contacts
    }
    
    // Constructor
    // Note: The id parameter is for specifying a document id
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

**Note:** Only the top level is required to implement `DocumentCodable` protocol; the nested model can just implement `CBLCodable` protocol.

#### Save model object into database
```Swift
// Create an employee object
var employee = Employee(name: "Jimmy")
employee.dob = dob
employee.address = Address(street: "1 Main Street")
employee.contacts = [Person(name: "Jackson", phone: "650-123-4567")]

// Save 
try employee.save(into: self.db)
```

#### Get model object from database
```Swift
let employee = try self.db.document(withID: "emp1", as: Employee.self)
```

### Query Results Decoding
In addition to encoding and decoding document API, two extensions to decode the model object from the query's result or to decode an array of model objects from the query's result set are defined.

#### Example
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

## API

### Encoder and Decoder API

#### CBLEncoder

```swift
func encode<T: CBLEncodable>(_ value: T) throws -> MutableDocument

func encode<T: CBLEncodable>(_ value: T, for documentID: String) throws -> MutableDocument

func encode<T: CBLEncodable>(_ value: T, into document: MutableDocument) throws -> MutableDocument
```

#### CBLDecoder

```swift
func decode<T: CBLDecodable>(_ type: T.Type, from document: Document) throws -> T

func decode<T: CBLDecodable>(_ type: T.Type, from result: Result) throws -> T
```

#### CBLCodable

```swift
public protocol CBLEncodable: Encodable { }

protocol CBLDecodable: Decodable { }

typealias CBLCodable = CBLEncodable & CBLDecodable
```

### DocumentDecodable API


#### DocumentDecodable

```Swift
public protocol DocumentฺEncodable: CBLEncodable {
    var document: MutableDocument! { get set }
}

public protocol DocumentDecodable: CBLDecodable {
    mutating func decoded(for document: Document)
}

public protocol DocumentCodable: DocumentฺEncodable, DocumentDecodable { }
```

#### DocumentCodable Extension
```Swift
mutating func save(into database: Database) throws
```

### Couchbase Lite API Extension

#### Database
```Swift
func document<T: DocumentDecodable>(withID id: String, as type: T.Type) throws -> T?

func saveDocument<T: DocumentฺEncodable>(_ encodable: T) throws
```

#### Document
```Swift
func decode<T: DocumentDecodable>(as type: T.Type) throws -> T
```

#### Result
```Swift
func decode<T: CBLDecodable>(as type: T.Type) throws -> T
```

#### ResultSet
```Swift
func decode<T: CBLDecodable>(as type: T.Type) throws -> [T]
```

