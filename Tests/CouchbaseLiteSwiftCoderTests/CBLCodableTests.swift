import XCTest
import CouchbaseLiteSwift
@testable import CouchbaseLiteSwiftCoder

final class CBLCodableTests: XCTestCase {
    func testEncode() throws {
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
    
    func testDecode() throws {
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
    
    func testCustomEncode() throws {
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
    
    func testCustomDecode() throws {
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
    
    func testTypedEncode() throws {
        let content = "MyData".data(using: .utf8)!
        let blob = Blob(contentType: "text/plain", data: content)
        
        let model = TypedModel(
            bool: true,
            double: 10.5, float: 10.5,
            int: 10, int8: 10, int16: 10, int32: 10, int64: 10,
            uint: 20, uint8: 20, uint16: 20, uint32: 20, uint64: 20,
            str: "Hello",
            date: "2000-01-01T00:00:00.000Z".toDate(),
            data: content,
            blob: blob)
        
        let encoder = CBLEncoder()
        let doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [
            "bool": true,
            "double": 10.5, "float": 10.5,
            "int": 10, "int8": 10, "int16": 10, "int32": 10, "int64": 10,
            "uint": 20, "uint8": 20, "uint16": 20, "uint32": 20, "uint64": 20,
            "str": "Hello",
            "date": "2000-01-01T00:00:00.000Z",
            "data": doc.blob(forKey: "data")!,
            "blob": doc.blob(forKey: "blob")!,
        ])
        XCTAssertEqual(doc.blob(forKey: "data")?.content, content)
        XCTAssertEqual(doc.blob(forKey: "blob")?.content, content)
    }
    
    func testTypedDecode() throws {
        let content = "MyData".data(using: .utf8)!
        let blob = Blob(contentType: "text/plain", data: content)
        
        let doc = MutableDocument(data: [
            "bool": true,
            "double": 10.5, "float": 10.5,
            "int": 10, "int8": 10, "int16": 10, "int32": 10, "int64": 10,
            "uint": 20, "uint8": 20, "uint16": 20, "uint32": 20, "uint64": 20,
            "str": "Hello", "date": "2000-01-01T00:00:00.000Z",
            "data": content, "blob": blob
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
        XCTAssertEqual(model.data, content)
        XCTAssertEqual(model.blob.content, content)
    }
    
    func testOptTypedEncode() throws {
        let content = "MyData".data(using: .utf8)!
        let blob = Blob(contentType: "text/plain", data: content)
        
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
        model.data = content
        model.blob = blob
        
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
            "date": "2000-12-01T00:00:00.000Z",
            "data": doc.blob(forKey: "data")!,
            "blob": doc.blob(forKey: "blob")!,
        ])
        XCTAssertEqual(doc.blob(forKey: "data")?.content, content)
        XCTAssertEqual(doc.blob(forKey: "blob")?.content, content)
    }
    
    func testOptTypedDecode() throws {
        var doc = MutableDocument()
        
        let content = "MyData".data(using: .utf8)!
        let blob = Blob(contentType: "text/plain", data: content)
        
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
        XCTAssertNil(model.data)
        XCTAssertNil(model.blob)
        
        doc = MutableDocument(data: [
            "bool": true,
            "double": 10.5, "float": 10.5,
            "int": 10, "int8": 10, "int16": 10, "int32": 10, "int64": 10,
            "uint": 20, "uint8": 20, "uint16": 20, "uint32": 20, "uint64": 20,
            "str": "Hello", "date": "2000-01-01T00:00:00.000Z",
            "data": content, "blob": blob
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
        XCTAssertEqual(model.data, content)
        XCTAssertEqual(model.blob?.content, content)
    }
    
    func testArrayEncode() throws {
        let date1 = "2000-01-01T00:00:00.000Z".toDate()
        let date2 = "2000-02-01T00:00:00.000Z".toDate()
        let data1 = "MyData1".data(using: .utf8)!
        let data2 = "MyData2".data(using: .utf8)!
        let blob1 = Blob(contentType: "text/plain", data: data1)
        let blob2 = Blob(contentType: "text/plain", data: data2)
        let person1 = Person(name: "Daniel", address: Address(street: "1 Main Street"))
        let person2 = Person(name: "James", address: Address(street: "2 Main Street"))
        
        var model = ArrayModel(
            bool: [],
            int: [],
            string: [],
            date: [],
            data: [],
            blob: [],
            codable: [])
        
        let encoder = CBLEncoder()
        var doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [
            "bool": [],
            "int": [],
            "string": [],
            "date": [],
            "data": [],
            "blob": [],
            "codable": []
        ])
        
        model = ArrayModel(
            bool: [true, false],
            int: [1, 2],
            string: ["s1", "s2"],
            date: [date1, date2],
            data: [data1, data2],
            blob: [blob1, blob2],
            codable: [person1, person2])
        
        doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [
            "bool": [true, false],
            "int": [1, 2],
            "string": ["s1", "s2"],
            "date": ["2000-01-01T00:00:00.000Z", "2000-02-01T00:00:00.000Z"],
            "data": doc.array(forKey: "data")!.toArray(),
            "blob": doc.array(forKey: "blob")!.toArray(),
            "codable": [["name": "Daniel", "address": ["street": "1 Main Street"]],
                         ["name": "James", "address": ["street": "2 Main Street"]]]
        ])
        XCTAssertEqual(doc.array(forKey: "data")!.toArray().map { ($0 as! Blob).content}, [data1, data2])
        XCTAssertEqual(doc.array(forKey: "blob")!.toArray().map { ($0 as! Blob).content}, [data1, data2])
    }
    
    func testArrayDecode() throws {
        let date1 = "2000-01-01T00:00:00.000Z".toDate()
        let date2 = "2000-02-01T00:00:00.000Z".toDate()
        let data1 = "MyData1".data(using: .utf8)!
        let data2 = "MyData2".data(using: .utf8)!
        let blob1 = Blob(contentType: "text/plain", data: data1)
        let blob2 = Blob(contentType: "text/plain", data: data2)
        let person1: [String : Any] = ["name": "Daniel", "address": ["street": "1 Main Street"]]
        let person2: [String : Any] = ["name": "James", "address": ["street": "2 Main Street"]]
        
        var doc = MutableDocument(data: [
            "bool": [],
            "int": [],
            "string": [],
            "date": [],
            "data": [],
            "blob": [],
            "codable": []
        ])
        
        let decoder = CBLDecoder()
        var model = try decoder.decode(ArrayModel.self, from: doc)
        XCTAssertEqual(model.bool, [])
        XCTAssertEqual(model.int, [])
        XCTAssertEqual(model.string, [])
        XCTAssertEqual(model.date, [])
        XCTAssertEqual(model.data, [])
        XCTAssertEqual(model.blob, [])
        XCTAssertEqual(model.codable.count, 0)
        
        doc = MutableDocument(data: [
            "bool": [true, false],
            "int": [1, 2],
            "string": ["s1", "s2"],
            "date": [date1, date2],
            "data": [data1, data2],
            "blob": [blob1, blob2],
            "codable": [person1, person2]
        ])
        
        model = try decoder.decode(ArrayModel.self, from: doc)
        XCTAssertEqual(model.bool, [true, false])
        XCTAssertEqual(model.int, [1, 2])
        XCTAssertEqual(model.string, ["s1", "s2"])
        XCTAssertEqual(model.date, [date1, date2])
        XCTAssertEqual(model.data, [data1, data2])
        XCTAssertEqual(model.blob, [blob1, blob2])
        XCTAssertEqual(model.codable[0].name, "Daniel")
        XCTAssertEqual(model.codable[0].address?.street, "1 Main Street")
        XCTAssertEqual(model.codable[1].name, "James")
        XCTAssertEqual(model.codable[1].address?.street, "2 Main Street")
    }
    
    func testOptArrayEncode() throws {
        let date1 = "2000-01-01T00:00:00.000Z".toDate()
        let date2 = "2000-02-01T00:00:00.000Z".toDate()
        let data1 = "MyData1".data(using: .utf8)!
        let data2 = "MyData2".data(using: .utf8)!
        let blob1 = Blob(contentType: "text/plain", data: data1)
        let blob2 = Blob(contentType: "text/plain", data: data2)
        let person1 = Person(name: "Daniel", address: Address(street: "1 Main Street"))
        let person2 = Person(name: "James", address: Address(street: "2 Main Street"))
        
        var model = OptArrayModel()
        
        let encoder = CBLEncoder()
        var doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [:])
        
        model.bool = [true, false]
        model.int = [1, 2]
        model.string = ["s1", "s2"]
        model.date = [date1, date2]
        model.data = [data1, data2]
        model.blob = [blob1, blob2]
        model.codable = [person1, person2]
        
        doc = try encoder.encode(model)
        XCTAssertTrue(doc.toDictionary() == [
            "bool": [true, false],
            "int": [1, 2],
            "string": ["s1", "s2"],
            "date": ["2000-01-01T00:00:00.000Z", "2000-02-01T00:00:00.000Z"],
            "data": doc.array(forKey: "data")!.toArray(),
            "blob": doc.array(forKey: "blob")!.toArray(),
            "codable": [["name": "Daniel", "address": ["street": "1 Main Street"]],
                         ["name": "James", "address": ["street": "2 Main Street"]]]
            ])
        XCTAssertEqual(doc.array(forKey: "data")!.toArray().map { ($0 as! Blob).content}, [data1, data2])
        XCTAssertEqual(doc.array(forKey: "blob")!.toArray().map { ($0 as! Blob).content}, [data1, data2])
    }
    
    func testOptArrayDecode() throws {
        let date1 = "2000-01-01T00:00:00.000Z".toDate()
        let date2 = "2000-02-01T00:00:00.000Z".toDate()
        let data1 = "MyData1".data(using: .utf8)!
        let data2 = "MyData2".data(using: .utf8)!
        let blob1 = Blob(contentType: "text/plain", data: data1)
        let blob2 = Blob(contentType: "text/plain", data: data2)
        let person1: [String : Any] = ["name": "Daniel", "address": ["street": "1 Main Street"]]
        let person2: [String : Any] = ["name": "James", "address": ["street": "2 Main Street"]]
        
        var doc = MutableDocument()
        
        let decoder = CBLDecoder()
        var model = try decoder.decode(OptArrayModel.self, from: doc)
        XCTAssertNil(model.bool)
        XCTAssertNil(model.int)
        XCTAssertNil(model.string)
        XCTAssertNil(model.date)
        XCTAssertNil(model.data)
        XCTAssertNil(model.blob)
        XCTAssertNil(model.codable)
        
        doc = MutableDocument(data: [
            "bool": [true, false],
            "int": [1, 2],
            "string": ["s1", "s2"],
            "date": [date1, date2],
            "data": [data1, data2],
            "blob": [blob1, blob2],
            "codable": [person1, person2]
        ])
        model = try decoder.decode(OptArrayModel.self, from: doc)
        
        XCTAssertEqual(model.bool, [true, false])
        XCTAssertEqual(model.int, [1, 2])
        XCTAssertEqual(model.string, ["s1", "s2"])
        XCTAssertEqual(model.date, [date1, date2])
        XCTAssertEqual(model.data, [data1, data2])
        XCTAssertEqual(model.blob, [blob1, blob2])
        XCTAssertEqual(model.codable![0].name, "Daniel")
        XCTAssertEqual(model.codable![0].address?.street, "1 Main Street")
        XCTAssertEqual(model.codable![1].name, "James")
        XCTAssertEqual(model.codable![1].address?.street, "2 Main Street")
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
