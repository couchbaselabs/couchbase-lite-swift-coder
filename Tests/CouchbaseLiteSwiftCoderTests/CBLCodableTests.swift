import XCTest
import CouchbaseLiteSwift
@testable import CouchbaseLiteSwiftCoder

final class CBLCodableTests: XCTestCase {
    func testEncoder() throws {
        let address = Address(street: "1 Main Street")
        var person = Person(name: "Daniel", address: address)
        
        let encoder = CBLEncoder()
        var doc = try encoder.encode(person)
        XCTAssertTrue(doc.toDictionary() == [
            "name": "Daniel",
            "address": ["street": "1 Main Street"],
        ])
        
        person.dob = "2000-01-01T00:00:00.000Z".toDate()
        person.contacts = [Person(name: "James")]
        person.dependents = 2
        doc = try encoder.encode(person)
        XCTAssertTrue(doc.toDictionary() == [
            "name": "Daniel",
            "dob": "2000-01-01T00:00:00.000Z",
            "address": ["street": "1 Main Street"],
            "contacts": [["name": "James"]],
            "dependents": 2,
        ])
        
        let photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        person.photo = photo
        doc = try encoder.encode(person)
        XCTAssertEqual(doc.blob(forKey: "photo"), photo)
    }
    
    func testDecoder() throws {
        let doc = MutableDocument(data: [
            "name": "Daniel",
            "dob": "2000-01-01T00:00:00.000Z",
            "address": ["street": "1 Main Street"],
        ])
        
        let decoder = CBLDecoder()
        var person = try decoder.decode(Person.self, from: doc)
        XCTAssertEqual(person.name, "Daniel")
        XCTAssertEqual(person.dob, "2000-01-01T00:00:00.000Z".toDate())
        XCTAssertEqual(person.address?.street, "1 Main Street")
        XCTAssertNil(person.contacts)
        XCTAssertNil(person.dependents)
        
        let contacts = MutableArrayObject(data: [["name": "James"]])
        let photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        doc.setBlob(photo, forKey: "photo")
        doc.setArray(contacts, forKey: "contacts")
        doc.setInt(2, forKey: "dependents")
        
        person = try decoder.decode(Person.self, from: doc)
        XCTAssertEqual(person.name, "Daniel")
        XCTAssertEqual(person.dob, "2000-01-01T00:00:00.000Z".toDate())
        XCTAssertEqual(person.photo, photo)
        XCTAssertEqual(person.address?.street, "1 Main Street")
        XCTAssertEqual(person.contacts?.count, 1)
        XCTAssertEqual(person.contacts?[0].name, "James")
        XCTAssertEqual(person.dependents, 2)
    }
    
    func testCustomEncoder() throws {
        var person = CustomPerson(name: "Daniel")
        
        let encoder = CBLEncoder()
        var doc = try encoder.encode(person)
        XCTAssertTrue(doc.toDictionary() == [
            "fullName": "Daniel"
        ])
        
        person.dob = "2000-01-01T00:00:00.000Z".toDate()
        person.contacts = [CustomPerson(name: "James")]
        person.address = Address(street: "1 Main Street")
        person.dependents = 2
        
        doc = try encoder.encode(person)
        XCTAssertTrue(doc.toDictionary() == [
            "fullName": "Daniel",
            "birthDate": "2000-01-01T00:00:00.000Z",
            "addresses": [["street": "1 Main Street"]],
            "additional": ["contacts": [["fullName": "James"]], "dependents": 2]
        ])
        
        let photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        person.photo = photo
        doc = try encoder.encode(person)
        XCTAssertEqual(doc.blob(forKey: "photo"), photo)
    }
    
    func testCustomDecoder() throws {
        let doc = MutableDocument(data: [
            "fullName": "Daniel"
        ])
        
        let decoder = CBLDecoder()
        var person = try decoder.decode(CustomPerson.self, from: doc)
        XCTAssertEqual(person.name, "Daniel")
        XCTAssertNil(person.dob)
        XCTAssertNil(person.photo)
        XCTAssertNil(person.contacts)
        XCTAssertNil(person.address)
        XCTAssertNil(person.dependents)
        
        let photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        doc.setBlob(photo, forKey: "photo")
        doc.setDate("2000-01-01T00:00:00.000Z".toDate(), forKey: "birthDate")
        
        let addresses = MutableArrayObject(data: [["street": "1 Main Street"]])
        doc.setArray(addresses, forKey: "addresses")
        
        let additional = MutableDictionaryObject()
        let contacts = MutableArrayObject(data: [["fullName": "James"]])
        additional.setArray(contacts, forKey: "contacts")
        additional.setInt(2, forKey: "dependents")
        doc.setDictionary(additional, forKey: "additional")
 
        person = try decoder.decode(CustomPerson.self, from: doc)
        XCTAssertEqual(person.name, "Daniel")
        XCTAssertEqual(person.dob, "2000-01-01T00:00:00.000Z".toDate())
        XCTAssertEqual(person.photo, photo)
        XCTAssertEqual(person.address?.street, "1 Main Street")
        XCTAssertEqual(person.contacts?.count, 1)
        XCTAssertEqual(person.contacts?[0].name, "James")
        XCTAssertEqual(person.dependents, 2)
    }
    
    func testTypedEncoder() throws {
        let model = TypedModel(
            bool: true,
            double: 10.5, float: 10.5,
            int: 10, int8: 10, int16: 10, int32: 10, int64: 10,
            uint: 20, uint8: 20, uint16: 20, uint32: 20, uint64: 20,
            str: "Hello",
            date: "2000-01-01T00:00:00.000Z".toDate())
        
        let encoder = CBLEncoder()
        let doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [
            "bool": true,
            "double": 10.5, "float": 10.5,
            "int": 10, "int8": 10, "int16": 10, "int32": 10, "int64": 10,
            "uint": 20, "uint8": 20, "uint16": 20, "uint32": 20, "uint64": 20,
            "str": "Hello",
            "date": "2000-01-01T00:00:00.000Z"
        ])
    }
    
    func testTypedDecoder() throws {
        let doc = MutableDocument(data: [
            "bool": true,
            "double": 10.5, "float": 10.5,
            "int": 10, "int8": 10, "int16": 10, "int32": 10, "int64": 10,
            "uint": 20, "uint8": 20, "uint16": 20, "uint32": 20, "uint64": 20,
            "str": "Hello", "date": "2000-01-01T00:00:00.000Z"
        ])
        
        let decoder = CBLDecoder()
        let model = try decoder.decode(TypedModel.self, from: doc)
        XCTAssertEqual(model.bool, true)
        XCTAssertEqual(model.double, 10.5)
        XCTAssertEqual(model.float, 10.5)
        XCTAssertEqual(model.int, 10)
        XCTAssertEqual(model.int8, 10)
        XCTAssertEqual(model.int16, 10)
        XCTAssertEqual(model.int32, 10)
        XCTAssertEqual(model.int64, 10)
        XCTAssertEqual(model.uint8, 20)
        XCTAssertEqual(model.uint16, 20)
        XCTAssertEqual(model.uint32, 20)
        XCTAssertEqual(model.uint64, 20)
        XCTAssertEqual(model.str, "Hello")
        XCTAssertEqual(model.date, "2000-01-01T00:00:00.000Z".toDate())
    }
    
    func testOptTypedEncoder() throws {
        var model = OptTypedModel()
        let encoder = CBLEncoder()
        var doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [:])
        
        model.bool = true
        model.double = 10.5
        model.float = 10.5
        model.int = 10
        model.int8 = 10
        model.int16 = 10
        model.int32 = 10
        model.int64 = 10
        model.uint = 100
        model.uint8 = 100
        model.uint32 = 100
        model.uint64 = 100
        model.str = "Hello World"
        model.date = "2000-12-01T00:00:00.000Z".toDate()
        
        doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [
            "bool": true,
            "double": 10.5,
            "float": 10.5,
            "int": 10,
            "int8": 10,
            "int16": 10,
            "int32": 10,
            "int64": 10,
            "uint": 100,
            "uint8": 100,
            "uint32": 100,
            "uint64": 100,
            "str": "Hello World",
            "date": "2000-12-01T00:00:00.000Z"
        ])
    }
    
    func testOptTypedDecoder() throws {
        var doc = MutableDocument()
        
        let decoder = CBLDecoder()
        var model = try decoder.decode(OptTypedModel.self, from: doc)
        XCTAssertNil(model.bool)
        XCTAssertNil(model.double)
        XCTAssertNil(model.float)
        XCTAssertNil(model.int)
        XCTAssertNil(model.int8)
        XCTAssertNil(model.int16)
        XCTAssertNil(model.int32)
        XCTAssertNil(model.int64)
        XCTAssertNil(model.uint8)
        XCTAssertNil(model.uint16)
        XCTAssertNil(model.uint32)
        XCTAssertNil(model.uint64)
        XCTAssertNil(model.str)
        XCTAssertNil(model.date)
        
        doc = MutableDocument(data: [
            "bool": true,
            "double": 10.5, "float": 10.5,
            "int": 10, "int8": 10, "int16": 10, "int32": 10, "int64": 10,
            "uint": 20, "uint8": 20, "uint16": 20, "uint32": 20, "uint64": 20,
            "str": "Hello", "date": "2000-01-01T00:00:00.000Z"
        ])
        
        model = try decoder.decode(OptTypedModel.self, from: doc)
        XCTAssertEqual(model.bool, true)
        XCTAssertEqual(model.double, 10.5)
        XCTAssertEqual(model.float, 10.5)
        XCTAssertEqual(model.int, 10)
        XCTAssertEqual(model.int8, 10)
        XCTAssertEqual(model.int16, 10)
        XCTAssertEqual(model.int32, 10)
        XCTAssertEqual(model.int64, 10)
        XCTAssertEqual(model.uint8, 20)
        XCTAssertEqual(model.uint16, 20)
        XCTAssertEqual(model.uint32, 20)
        XCTAssertEqual(model.uint64, 20)
        XCTAssertEqual(model.str, "Hello")
        XCTAssertEqual(model.date, "2000-01-01T00:00:00.000Z".toDate())
    }
}

public func ==(lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

extension String {
    func toDate() -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = NSTimeZone.local
        return formatter.date(from: self)!
    }
}
