import XCTest
import CouchbaseLiteSwift
@testable import CouchbaseLiteSwiftCoder

final class DocumentCodableTests: XCTestCase {
    var db: Database!
    
    override func setUpWithError() throws {
        try Database.delete(withName: "testdb")
        db = try Database(name: "testdb")
    }
    
    override func tearDownWithError() throws {
        try db.delete()
    }
    
    func testSaveModel() throws {
        var student = Student(id: "doc1", name: "Daniel")
        student.address = Address(street: "1 Main Street")
        student.contacts = [Person(name: "James")]
        student.dob = "1980-01-01T00:00:00.000Z".toDate()
        student.photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        try student.save(into: self.db)
        
        XCTAssertEqual(student.document?.id, "doc1")
        XCTAssertTrue(student.document?.toDictionary() ?? [:] == [
            "name": "Daniel",
            "address": ["street": "1 Main Street"],
            "dob": "1980-01-01T00:00:00.000Z",
            "contacts": [["name": "James"]],
            "photo": student.photo!
        ])
        
        let doc = self.db.document(withID: "doc1")
        XCTAssertTrue(doc?.toDictionary() ?? [:] == [
            "name": "Daniel",
            "address": ["street": "1 Main Street"],
            "dob": "1980-01-01T00:00:00.000Z",
            "contacts": [["name": "James"]],
            "photo": doc!.blob(forKey: "photo")!
        ])
    }
    
    func testGetModel() throws {
        let photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        let data: [String : Any] = [
            "name": "Daniel",
            "address": ["street": "1 Main Street"],
            "dob": "1980-01-01T00:00:00.000Z",
            "contacts": [["name": "James"]],
            "photo": photo
        ]
        let doc = MutableDocument(id: "doc1", data: data)
        try self.db.saveDocument(doc)
        
        let student = try self.db.document(withID: "doc1", as: Student.self)
        XCTAssertNotNil(student)
        XCTAssertNotNil(student?.document)
        XCTAssertTrue(student?.document?.toDictionary() ?? [:] == [
            "name": "Daniel",
            "address": ["street": "1 Main Street"],
            "dob": "1980-01-01T00:00:00.000Z",
            "contacts": [["name": "James"]],
            "photo": student!.document!.blob(forKey: "photo")!
        ])
        
        XCTAssertEqual(student?.name, "Daniel")
        XCTAssertEqual(student?.address?.street, "1 Main Street")
        XCTAssertEqual(student?.dob, "1980-01-01T00:00:00.000Z".toDate())
        XCTAssertEqual(student?.contacts?.count, 1)
        XCTAssertEqual(student?.contacts?.first?.name, "James")
        XCTAssertEqual(student?.photo?.content, photo.content)
    }
    
    func testDecodeDocument() throws {
        let photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        let data: [String : Any] = [
            "name": "Daniel",
            "address": ["street": "1 Main Street"],
            "dob": "1980-01-01T00:00:00.000Z",
            "contacts": [["name": "James"]],
            "photo": photo
        ]
        let doc = MutableDocument(id: "doc1", data: data)
        let student = try doc.decode(Student.self)
        
        XCTAssertEqual(student.document, doc)
        XCTAssertEqual(student.name, "Daniel")
        XCTAssertEqual(student.address?.street, "1 Main Street")
        XCTAssertEqual(student.dob, "1980-01-01T00:00:00.000Z".toDate())
        XCTAssertEqual(student.contacts?.count, 1)
        XCTAssertEqual(student.contacts?.first?.name, "James")
        XCTAssertEqual(student.photo?.content, photo.content)
    }
    
    func testQueryResultAsModel() throws {
        let photo = Blob(contentType: "text/plain", data: "MyPhoto".data(using: .utf8)!)
        let doc = MutableDocument(id: "doc1", data: [
            "name": "Daniel",
            "address": ["street": "1 Main Street"],
            "dob": "1980-01-01T00:00:00.000Z",
            "contacts": [["name": "James"]],
            "photo": photo
        ])
        try self.db.saveDocument(doc)
        
        let query = QueryBuilder
            .select(SelectResult.property("name"),
                    SelectResult.property("address"),
                    SelectResult.property("dob"),
                    SelectResult.property("contacts"),
                    SelectResult.property("photo"))
            .from(DataSource.database(self.db))
        
        var results = try query.execute()
        var student = try results.allResults().first?.decode(Student.self)
        XCTAssertEqual(student?.name, "Daniel")
        XCTAssertEqual(student?.address?.street, "1 Main Street")
        XCTAssertEqual(student?.dob, "1980-01-01T00:00:00.000Z".toDate())
        XCTAssertEqual(student?.contacts?.count, 1)
        XCTAssertEqual(student?.contacts?.first?.name, "James")
        XCTAssertEqual(student?.photo?.content, photo.content)
        
        results = try query.execute()
        let students = try results.decode(Student.self)
        XCTAssertEqual(students.count, 1)
        student = students.first
        XCTAssertEqual(student?.name, "Daniel")
        XCTAssertEqual(student?.address?.street, "1 Main Street")
        XCTAssertEqual(student?.dob, "1980-01-01T00:00:00.000Z".toDate())
        XCTAssertEqual(student?.contacts?.count, 1)
        XCTAssertEqual(student?.contacts?.first?.name, "James")
        XCTAssertEqual(student?.photo?.content, photo.content)
    }
}
