import CouchbaseLiteSwift

public protocol DocumentฺEncodable: CBLEncodable {
    var document: MutableDocument? { get set }
}

public protocol DocumentDecodable: CBLDecodable {
    mutating func decoded(for document: Document)
}

public protocol DocumentCodable: DocumentฺEncodable, DocumentDecodable { }

extension DocumentฺEncodable {
    public mutating func save(into database: Database, forID id: String? = nil) throws {
        let document = try CBLEncoder().encode(self, into: self.document ?? MutableDocument(id: id))
        try database.saveDocument(document)
        if self.document == nil { self.document = document }
    }
}

extension DocumentDecodable {
    public mutating func decoded(for document: Document) { }
}

extension DocumentCodable {
    public mutating func decoded(for document: Document) {
        self.document = document.toMutable()
    }
}

extension Database {
    public func document<T: DocumentDecodable>(withID id: String, as type: T.Type) throws -> T? {
        guard let document = self.document(withID: id) else { return nil }
        return try document.decode(type)
    }
    
    public func saveDocument<T: DocumentฺEncodable>(_ encodable: inout T, forID id: String? = nil) throws {
        try encodable.save(into: self, forID: id)
    }
}

extension Document {
    public func decode<T: DocumentDecodable>(_ type: T.Type) throws -> T {
        var decoable = try CBLDecoder().decode(T.self, from: self)
        decoable.decoded(for: self)
        return decoable
    }
}

extension Result {
    public func decode<T: CBLDecodable>(_ type: T.Type) throws -> T {
        return try CBLDecoder().decode(T.self, from: self)
    }
}

extension ResultSet {
    public func decode<T: CBLDecodable>(_ type: T.Type) throws -> [T] {
        var decoded: [T] = []
        for result in self.allResults() {
            decoded.append(try result.decode(type))
        }
        return decoded
    }
}
