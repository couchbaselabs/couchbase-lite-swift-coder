import Foundation
import CouchbaseLiteSwift

public protocol CBLDecodable: Decodable { }

public class CBLDecoder {
    func decode<T: CBLDecodable>(_ type: T.Type, from document: Document) throws -> T {
        let decoder = _CBLDecoder(with: document)
        return try type.init(from: decoder)
    }
    
    func decode<T: CBLDecodable>(_ type: T.Type, from result: Result) throws -> T {
        let decoder = _CBLDecoder(with: result)
        return try type.init(from: decoder)
    }
}

private class _CBLDecoder: Decoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var containers: [Any] = []
    
    init(with document: Document) {
        containers.append(document)
    }
    
    init(with result: Result) {
        containers.append(result)
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = DictionaryDecodingContainer<Key>(decoder: self, dictionary: dictionaryContainer())
        return KeyedDecodingContainer.init(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return ArrayDecodingContainer(decoder: self, array: arrayContainer())
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return ValueDecodingContainer(decoder: self)
    }
    
    func dictionaryContainer() -> DictionaryProtocol {
        return containers.last as! DictionaryProtocol
    }
    
    func arrayContainer() -> ArrayProtocol {
        return containers.last as! ArrayProtocol
    }
    
    func pushContainer(_ container: Any) {
        containers.append(container)
    }
    
    func popContainer() {
        assert(containers.count > 1)
        containers.removeLast()
    }
    
    func unbox<T: Decodable>(_ value: Any?, as type: T.Type) throws -> T? {
        switch type {
        case is CBLDecodable.Type:
            guard let dict = value as? DictionaryObject else { return nil }
            pushContainer(dict)
            let v = try T.init(from: self)
            popContainer()
            return v
        case is ArrayType.Type:
            guard let array = value as? ArrayObject else { return nil }
            pushContainer(array)
            let v = try T.init(from: self)
            popContainer()
            return v
        case is Data.Type:
            guard let blob = value as? Blob else { return nil }
            return blob.content as? T
        default:
            return value as? T
        }
    }
}

private struct DictionaryDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decoder: _CBLDecoder
    
    let dictionary: DictionaryProtocol
    
    let codingPath: [CodingKey]
    
    init(decoder: _CBLDecoder, dictionary: DictionaryProtocol) {
        self.decoder = decoder
        self.dictionary = dictionary
        self.codingPath = decoder.codingPath
    }
    
    var allKeys: [Key] {
        return self.dictionary.keys.compactMap { Key(stringValue: $0) }
    }
    
    func contains(_ key: Key) -> Bool {
        return dictionary.contains(key: key.stringValue)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        return false
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return dictionary.boolean(forKey: key.stringValue)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return dictionary.double(forKey: key.stringValue)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return dictionary.float(forKey: key.stringValue)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return dictionary.int(forKey: key.stringValue)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return Int8(dictionary.int(forKey: key.stringValue))
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return Int16(dictionary.int(forKey: key.stringValue))
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return Int32(dictionary.int(forKey: key.stringValue))
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return dictionary.int64(forKey: key.stringValue)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return UInt(dictionary.int(forKey: key.stringValue))
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return UInt8(dictionary.int(forKey: key.stringValue))
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return UInt16(dictionary.int(forKey: key.stringValue))
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return UInt32(dictionary.int(forKey: key.stringValue))
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return UInt64(dictionary.int(forKey: key.stringValue))
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        
        var value: Any?
        switch type {
        case is Date.Type:
            value = dictionary.date(forKey: key.stringValue)
        default:
            value = dictionary.value(forKey: key.stringValue)
        }
        
        let unboxed = try self.decoder.unbox(value, as: type)
        guard let decoded = unboxed else {
            throw DecodingError.unsupportedTypeError(type: type, path: self.decoder.codingPath)
        }
        return decoded
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
    -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        
        guard let dict = dictionary.dictionary(forKey: key.stringValue) else {
            throw DecodingError.invalidValueError(type: type, path: self.decoder.codingPath)
        }
        
        let container = DictionaryDecodingContainer<NestedKey>(decoder: decoder, dictionary: dict)
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        
        guard let array = dictionary.array(forKey: key.stringValue) else {
            throw DecodingError.invalidValueError(type: Array<Any>.self, path: self.codingPath)
        }
        
        return ArrayDecodingContainer(decoder: decoder, array: array)
    }
    
    func superDecoder() throws -> Decoder {
        return self.decoder
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        return self.decoder
    }
    
    func checkExists(forKey key: Key) throws {
        if !dictionary.contains(key: key.stringValue) {
            throw DecodingError.keyNotFoundError(key: key, path: codingPath)
        }
    }
}

private struct ArrayDecodingContainer: UnkeyedDecodingContainer {
    let decoder: _CBLDecoder
    
    let array: ArrayProtocol
    
    let codingPath: [CodingKey]
    
    var count: Int? {
        return self.array.count
    }
    
    var isAtEnd: Bool {
        return currentIndex == count
    }
    
    var currentIndex: Int = 0
    
    init(decoder: _CBLDecoder, array: ArrayProtocol) {
        self.decoder = decoder
        self.array = array
        self.codingPath = decoder.codingPath
    }
    
    mutating func decodeNil() throws -> Bool {
        return false
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return array.boolean(at: currentIndex)
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return array.string(at: currentIndex) ?? ""
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return array.double(at: currentIndex)
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return array.float(at: currentIndex)
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return array.int(at: currentIndex)
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return Int8(array.int(at: currentIndex))
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return Int16(array.int(at: currentIndex))
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return Int32(array.int(at: currentIndex))
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return array.int64(at: currentIndex)
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return UInt(array.int(at: currentIndex))
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return UInt8(array.int(at: currentIndex))
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return UInt16(array.int(at: currentIndex))
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        
        return UInt32(array.int(at: currentIndex))
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        return UInt64(array.int64(at: currentIndex))
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        var value: Any?
        switch type {
        case is Date.Type:
            value = array.date(at: currentIndex)
        default:
            value = array.value(at: currentIndex)
        }
        
        let unboxed = try self.decoder.unbox(value, as: type)
        guard let decoded = unboxed else {
            throw DecodingError.invalidValueError(type: type, path: codingPath)
        }
        return decoded
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
    -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        guard let dict = array.dictionary(at: currentIndex) else {
            throw DecodingError.invalidValueError(type: type, path: self.decoder.codingPath)
        }
        
        let container = DictionaryDecodingContainer<NestedKey>(decoder: decoder, dictionary: dict)
        return KeyedDecodingContainer.init(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        
        guard let arrayObject = array.array(at: currentIndex) else {
            throw DecodingError.invalidValueError(type: Array<Any>.self, path: self.decoder.codingPath)
        }
        
        return ArrayDecodingContainer(decoder: decoder, array: arrayObject)
    }
    
    mutating func superDecoder() throws -> Decoder {
        return self.decoder
    }
}

private struct ValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: _CBLDecoder
    
    let codingPath: [CodingKey]
    
    init(decoder: _CBLDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }
    
    func decodeNil() -> Bool {
        return false
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try T.init(from: self.decoder)
    }
}

// CBL's Value

extension Blob : Decodable {
    public convenience init(from decoder: Decoder) throws { fatalError() }
}

// Error

extension DecodingError {
    static func keyNotFoundError(key: CodingKey, path: [CodingKey]) -> DecodingError {
        let description = "No value associated with \(key.stringValue) key."
        let context = DecodingError.Context.init(codingPath: path, debugDescription: description)
        return DecodingError.keyNotFound(key, context)
    }
    
    static func invalidValueError(type: Any.Type, path: [CodingKey]) -> DecodingError {
        let description = "Invalid Couchbase Lite value for decoding '\(type)'"
        let context = DecodingError.Context.init(codingPath: path, debugDescription: description)
        return DecodingError.typeMismatch(type, context)
    }
    
    static func unsupportedTypeError(type: Any.Type, path: [CodingKey]) -> DecodingError {
        let description = "Decoding or unsupported data type error for data type '\(type)'"
        let context = DecodingError.Context.init(codingPath: path, debugDescription: description)
        return DecodingError.typeMismatch(type, context)
    }
}

// Array Type

protocol ArrayType {}
extension Array : ArrayType {}
