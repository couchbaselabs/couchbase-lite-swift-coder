import Foundation
import CouchbaseLiteSwift

public protocol CBLEncodable: Encodable { }

public class CBLEncoder {
    public func encode<T: CBLEncodable>(_ value: T) throws -> MutableDocument {
        return try encode(value, into: MutableDocument())
    }
    
    public func encode<T: CBLEncodable>(_ value: T, for documentID: String) throws -> MutableDocument {
        return try encode(value, into: MutableDocument(id: documentID))
    }
    
    @discardableResult 
    public func encode<T: CBLEncodable>(_ value: T, into document: MutableDocument) throws -> MutableDocument {
        let encoder = _CBLEncoder.init(with: document)
        try value.encode(to: encoder)
        return encoder.document
    }
}

private class _CBLEncoder: Encoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    let document: MutableDocument
    
    var containers: [Any] = []
    
    init(with document: MutableDocument) {
        self.document = document
        containers.append(document)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = DictionaryEncodingContainer<Key>(encoder: self, codingPath: codingPath,
                                                         dictionary: dictionaryContainer())
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return ArrayEncodingContainer(encoder: self, codingPath: codingPath, array: arrayContainer())
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return ValueEncodingContainer(encoder: self, codingPath: codingPath)
    }
    
    func dictionaryContainer() -> MutableDictionaryProtocol {
        return containers.last as! MutableDictionaryProtocol
    }
    
    func arrayContainer() -> MutableArrayProtocol {
        return containers.last as! MutableArrayProtocol
    }
    
    func pushContainer(_ container: Any) {
        containers.append(container)
    }
    
    func popContainer() -> Any {
        assert(containers.count > 1)
        return containers.popLast()!
    }
    
    func boxValue<T>(_ value: T) throws -> Any where T : Encodable {
        switch value {
        case _ as CBLEncodable:
            pushContainer(MutableDictionaryObject())
            try value.encode(to: self)
            return popContainer()
        case _ as Array<Any>:
            pushContainer(MutableArrayObject())
            try value.encode(to: self)
            return popContainer()
        default:
            return value
        }
    }
}

private struct DictionaryEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: _CBLEncoder
    
    var codingPath: [CodingKey]
    
    let dictionary: MutableDictionaryProtocol
    
    mutating func encodeNil(forKey key: Key) throws {
        dictionary.setValue(nil, forKey: key.stringValue)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        
        let boxed = try encoder.boxValue(value)
        dictionary.setValue(boxed, forKey: key.stringValue)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        
        self.codingPath.append(key)
        
        let dict = MutableDictionaryObject()
        dictionary.setDictionary(dict, forKey: key.stringValue)
        
        let container = DictionaryEncodingContainer<NestedKey>(
            encoder: self.encoder, codingPath: self.codingPath, dictionary: dict)
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        
        self.codingPath.append(key)
        
        let array = MutableArrayObject()
        dictionary.setArray(array, forKey: key.stringValue)
        
        return ArrayEncodingContainer(
            encoder: self.encoder, codingPath: self.codingPath, array: array)
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        return encoder
    }
}

private struct ArrayEncodingContainer: UnkeyedEncodingContainer {
    let encoder: _CBLEncoder
    
    let codingPath: [CodingKey]
    
    let array: MutableArrayProtocol
    
    var count: Int { return array.count }
    
    mutating func encodeNil() throws {
        array.addValue(nil)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        self.encoder.codingPath.append(IndexCodingKey(intValue: self.count)!)
        defer { self.encoder.codingPath.removeLast() }
        
        let boxed = try encoder.boxValue(value)
        array.addValue(boxed)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        var path = codingPath
        path.append(IndexCodingKey(intValue: self.count)!)
        
        let dict = MutableDictionaryObject()
        array.addDictionary(dict)
        
        let container = DictionaryEncodingContainer<NestedKey>(
            encoder: encoder, codingPath: path, dictionary: dict)
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        var path = codingPath
        path.append(IndexCodingKey(intValue: self.count)!)
        
        let arrayObj = MutableArrayObject()
        self.array.addArray(arrayObj)
        
        return ArrayEncodingContainer.init(
            encoder: encoder, codingPath: path, array: arrayObj)
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder
    }
}

private struct ValueEncodingContainer: SingleValueEncodingContainer {
    let encoder: _CBLEncoder
    
    let codingPath: [CodingKey]
    
    mutating func encodeNil() throws { }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try value.encode(to: self.encoder)
    }
}

struct IndexCodingKey : CodingKey {
    var stringValue: String
    
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// CBL's Value

extension Blob : Encodable {
    public func encode(to encoder: Encoder) throws { fatalError() }
}

// Optional

extension Optional: CBLEncodable where Wrapped: CBLEncodable { }
