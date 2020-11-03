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
    
    var storage: [Any] = []
    
    init(with document: Document) {
        storage.append(document)
    }
    
    init(with result: Result) {
        storage.append(result)
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
        return storage.last as! DictionaryProtocol
    }
    
    func arrayContainer() -> ArrayProtocol {
        return storage.last as! ArrayProtocol
    }
    
    func topStorageItem() -> Any {
        assert(storage.count > 0)
        return storage.last!
    }
    
    func pushStorage(_ item: Any) {
        storage.append(item)
    }
    
    func popContainer() {
        assert(storage.count > 1)
        storage.removeLast()
    }
}

extension _CBLDecoder {
    func unbox(_ value: Any, as type: Bool.Type) throws -> Bool {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.boolValue
    }
    
    func unbox(_ value: Any, as type: String.Type) throws -> String {
        guard let string = value as? String else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return string
    }
    
    func unbox(_ value: Any, as type: Double.Type) throws -> Double {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.doubleValue
    }
    
    func unbox(_ value: Any, as type: Float.Type) throws -> Float {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.floatValue
    }
    
    func unbox(_ value: Any, as type: Int.Type) throws -> Int {
        if let int = value as? Int { return int }
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.intValue
    }
    
    func unbox(_ value: Any, as type: Int8.Type) throws -> Int8 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.int8Value
    }
    
    func unbox(_ value: Any, as type: Int16.Type) throws -> Int16 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.int16Value
    }
    
    func unbox(_ value: Any, as type: Int32.Type) throws -> Int32 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.int32Value
    }
    
    func unbox(_ value: Any, as type: Int64.Type) throws -> Int64 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.int64Value
    }
    
    func unbox(_ value: Any, as type: UInt.Type) throws -> UInt {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.uintValue
    }
    
    func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.uint8Value
    }
    
    func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.uint16Value
    }
    
    func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.uint32Value
    }
    
    func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64 {
        guard let number = value as? NSNumber else {
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
        }
        return number.uint64Value
    }
    
    func unbox<T: Decodable>(_ value: Any, as type: T.Type) throws -> T {
        switch type {
        case is ArrayType.Type:
            guard let array = value as? ArrayObject else {
                throw DecodingError.typeMismatchError(type, value, self.codingPath)
            }
            pushStorage(array)
            let v = try T.init(from: self)
            popContainer()
            return v
        case is Blob.Type:
            guard let blob = value as? Blob else {
                throw DecodingError.typeMismatchError(type, value, self.codingPath)
            }
            return blob as! T
        case is Data.Type:
            guard let blob = value as? Blob else {
                throw DecodingError.typeMismatchError(type, value, self.codingPath)
            }
            return blob.content as! T
        case is Date.Type:
            guard let date = value as? Date else {
                throw DecodingError.typeMismatchError(type, value, self.codingPath)
            }
            return date as! T
        case is CBLDecodable.Type:
            pushStorage(value)
            let v = try T.init(from: self)
            popContainer()
            return v
        default:
            throw DecodingError.typeMismatchError(type, value, self.codingPath)
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
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Bool.self)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: String.self)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        let double = try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Double.self)
        return double
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Float.self)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Int.self)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Int8.self)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Int16.self)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Int32.self)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: Int64.self)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: UInt.self)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: UInt8.self)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: UInt16.self)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: UInt32.self)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        try checkExists(forKey: key)
        return try decoder.unbox(dictionary.value(forKey: key.stringValue)!, as: UInt64.self)
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
        
        guard let v = value else {
            let rawValue = dictionary.value(forKey: key.stringValue)!
            throw DecodingError.typeMismatchError(type, rawValue, self.decoder.codingPath)
        }
        return try self.decoder.unbox(v, as: type)
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
        return try decoder.unbox(array.value(at: currentIndex)!, as: Bool.self)
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: String.self)
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: Double.self)
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: Float.self)
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: Int.self)
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: Int8.self)
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: Int16.self)
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: Int32.self)
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: Int64.self)
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: UInt.self)
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: UInt8.self)
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: UInt16.self)
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: UInt32.self)
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        self.decoder.codingPath.append(IndexCodingKey(intValue: currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }
        defer { self.currentIndex += 1 }
        return try decoder.unbox(array.value(at: currentIndex)!, as: UInt64.self)
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
        guard let v = value else {
            let rawValue = array.value(at: currentIndex)!
            throw DecodingError.typeMismatchError(type, rawValue, self.decoder.codingPath)
        }
        return try self.decoder.unbox(v, as: type)
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
    
    func decode(_ type: Bool.Type) throws -> Bool {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Bool.self)
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: String.self)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Double.self)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Float.self)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Int.self)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Int8.self)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Int16.self)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Int32.self)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: Int64.self)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: UInt.self)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: UInt8.self)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: UInt16.self)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: UInt32.self)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: UInt64.self)
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try self.decoder.unbox(self.decoder.topStorageItem(), as: T.self)
    }
}

// CBL's Value

extension Blob : CBLDecodable {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let blob = try container.decode(Blob.self)
        self.init(contentType: blob.contentType ?? "application/octet-stream", data: blob.content!)
    }
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
    
    static func typeMismatchError(_ expType: Any.Type, _ value: Any, _ path: [CodingKey]) -> DecodingError {
        // let valueType =
        let description = "Expected to decode \(expType) but found \(type(of: value)) instead."
        let context = DecodingError.Context.init(codingPath: path, debugDescription: description)
        return DecodingError.typeMismatch(expType, context)
    }
    
    static func dataNotFitError(type: Any.Type, path: [CodingKey], value: Any) -> DecodingError {
        // let valueType = type(of: value)
        let description = "Data type \(value.self) does not fit in \(type)."
        let context = DecodingError.Context.init(codingPath: path, debugDescription: description)
        return DecodingError.typeMismatch(type, context)
    }
}

// Array Type

protocol ArrayType {}
extension Array : ArrayType {}
