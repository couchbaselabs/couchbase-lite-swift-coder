import CouchbaseLiteSwift

public protocol DocumentฺEncodable: CBLEncodable {
    var document: MutableDocument! { get set }
}

public protocol DocumentDecodable: CBLDecodable {
    mutating func decoded(for document: Document)
}

public protocol DocumentCodable: DocumentฺEncodable, DocumentDecodable { }

extension DocumentฺEncodable {
    public func save(into database: Database) throws {
        let document = try CBLEncoder().encode(self, into: self.document)
        try database.saveDocument(document)
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
        return try document.decode(as: type)
    }
    
    public func saveDocument<T: DocumentฺEncodable>(_ encodable: T) throws {
        try encodable.save(into: self)
    }
}

extension Document {
    public func decode<T: DocumentDecodable>(as type: T.Type) throws -> T {
        var decoable = try CBLDecoder().decode(T.self, from: self)
        decoable.decoded(for: self)
        return decoable
    }
}

extension Result {
    public func decode<T: CBLDecodable>(as type: T.Type) throws -> T {
        return try CBLDecoder().decode(T.self, from: self)
    }
}

extension ResultSet {
    public func decode<T: CBLDecodable>(as type: T.Type) throws -> [T] {
        var decoded: [T] = []
        for result in self.allResults() {
            decoded.append(try result.decode(as: type))
        }
        return decoded
    }
}
