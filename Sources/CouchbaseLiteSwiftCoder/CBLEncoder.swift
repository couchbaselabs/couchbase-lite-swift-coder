import Foundation
import CouchbaseLiteSwift

public protocol CBLEncodable: Encodable { }

open class CBLEncoder {
    public init() {}
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
    
    var storage: [Any] = []
    
    /// Returns whether a new element can be encoded at this coding path.
    var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding
        // path (even if it's a nil key from an unkeyed container).
        //
        // At the same time, every time a container is requested, a new value gets pushed onto the
        // storage stack. If there are more values on the storage stack than on the coding path,
        // it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack,
        // we MUST push a key onto the coding path.
        //
        // Things which will not request containers do not need to have the coding path extended
        // for them but always putting the coding path could be a good idea for logic consistency.
        return self.storage.count == self.codingPath.count
    }
    
    init(with document: MutableDocument) {
        self.document = document
        storage.append(document)
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
        if self.canEncodeNewValue {
            pushStorage(MutableDictionaryObject())
        }
        guard let container = storage.last as? MutableDictionaryProtocol else {
            preconditionFailure("Invalid dictionary container requested at path '\(self.codingPath)'")
        }
        return container
    }
    
    func arrayContainer() -> MutableArrayProtocol {
        if self.canEncodeNewValue {
            pushStorage(MutableArrayObject())
        }
        guard let container = storage.last as? MutableArrayProtocol else {
            preconditionFailure("Invalid array container requested at path '\(self.codingPath)'")
        }
        return container
    }
    
    func pushStorage(_ item: Any) {
        storage.append(item)
    }
    
    func popStorage() -> Any {
        assert(storage.count > 1)
        return storage.popLast()!
    }
}

extension _CBLEncoder {
    func box<T>(_ value: T) throws -> Any where T : Encodable {
        switch value {
        case is Array<Any>:
            try value.encode(to: self)
            return popStorage()
        case is Blob:
            return value
        case is Data:
            return Blob(data: value as! Data)
        case is Date:
            return value
        case is CBLEncodable:
            try value.encode(to: self)
            return popStorage()
        default:
            throw EncodingError.invalidValueError(value: value, path: self.codingPath)
        }
    }
}

private struct DictionaryEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: _CBLEncoder
    
    var codingPath: [CodingKey]
    
    let dictionary: MutableDictionaryProtocol
    
    mutating func encodeNil(forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(nil, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setBoolean(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setString(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setDouble(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setFloat(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setInt(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setInt64(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(value, forKey: key.stringValue)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        dictionary.setValue(try encoder.box(value), forKey: key.stringValue)
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
        self.encoder.codingPath.append(IndexCodingKey(intValue: self.count)!)
        defer { self.encoder.codingPath.removeLast() }
        array.addValue(nil)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        self.encoder.codingPath.append(IndexCodingKey(intValue: self.count)!)
        defer { self.encoder.codingPath.removeLast() }
        
        // Workaround:
        // With the synthesized code, the UnkeyedEncodingContainer is not called with any
        // typed overloading encode methods, check type and encode value directly. Note
        // that the same problem doesn't occur to KeyedEncodingContainer.
        switch value {
        case is Bool,
             is String,
             is Double,
             is Float,
             is Int,
             is Int8,
             is Int16,
             is Int32,
             is Int64,
             is UInt,
             is UInt8,
             is UInt16,
             is UInt32,
             is UInt64:
            array.addValue(value)
        default:
            array.addValue(try self.encoder.box(value))
        }
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
    
    mutating func encodeNil() throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(NSNull())
    }
    
    mutating func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(value)
    }
        
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        assertCanEncodeNewValue()
        self.encoder.pushStorage(try encoder.box(value))
    }
    
    private func assertCanEncodeNewValue() {
        precondition(self.encoder.canEncodeNewValue,
                     "Attempt to encode value through single value container when previously " +
                     "value already encoded.")
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

// Error

extension EncodingError {
    static func invalidValueError(value: Any, path: [CodingKey]) -> EncodingError {
        let description = "Unsupported or invalid value type to encode"
        let context = EncodingError.Context(codingPath: path, debugDescription: description)
        return EncodingError.invalidValue(value, context)
    }
}

// CBL's Value

extension Blob : CBLEncodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
    
    convenience init(data: Data) {
        self.init(contentType: "application/octet-stream", data: data)
    }
}

// Optional

extension Optional: CBLEncodable where Wrapped: CBLEncodable { }
