import CouchbaseLiteSwift
@testable import CouchbaseLiteSwiftCoder

struct Person: CBLCodable {
    var name: String
    var dob: Date?
    var photo: Blob?
    var address: Address?
    var contacts: [Person]?
    var dependents: Int?
}

struct Address: CBLCodable {
    let street: String
}

struct CustomPerson: CBLCodable {
    var name: String
    var dob: Date?
    var photo: Blob?
    var address: Address?
    var contacts: [CustomPerson]?
    var dependents: Int?
    
    enum Keys: String, CodingKey {
        case name = "fullName"
        case photo
        case dob = "birthDate"
        case addresses
        case additional
    }
    
    enum AdditionalKeys: String, CodingKey {
        case contacts
        case dependents
    }
    
    init(name: String) {
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let main = try decoder.container(keyedBy: Keys.self)
        self.name = try main.decode(String.self, forKey: .name)
        self.dob = try main.decodeIfPresent(Date.self, forKey: .dob)
        self.photo = try main.decodeIfPresent(Blob.self, forKey: .photo)
        
        if (main.contains(.additional)) {
            let add = try main.nestedContainer(keyedBy: AdditionalKeys.self, forKey: .additional)
            self.contacts = try add.decodeIfPresent([CustomPerson].self, forKey: .contacts)
            self.dependents = try add.decodeIfPresent(Int.self, forKey: .dependents)
        }
        
        if (main.contains(.addresses)) {
            var addresses = try main.nestedUnkeyedContainer(forKey: .addresses)
            self.address = try addresses.decodeIfPresent(Address.self)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var main = encoder.container(keyedBy: Keys.self)
        try main.encode (self.name, forKey: .name)
        try main.encodeIfPresent(self.dob, forKey: .dob)
        try main.encodeIfPresent(self.photo, forKey: .photo)
        
        if self.contacts != nil || self.dependents != nil {
            var add = main.nestedContainer(keyedBy: AdditionalKeys.self, forKey: .additional)
            try add.encodeIfPresent(self.contacts, forKey: .contacts)
            try add.encodeIfPresent(self.dependents, forKey: .dependents)
        }
        
        if let address = self.address {
            var addresses = main.nestedUnkeyedContainer(forKey: .addresses)
            try addresses.encode(address)
        }
    }
}

struct TypedModel: CBLCodable {
    var bool: Bool
    var double: Double
    var float: Float
    var int: Int
    var int8: Int8
    var int16: Int16
    var int32: Int32
    var int64: Int64
    var uint: UInt
    var uint8: UInt8
    var uint16: UInt16
    var uint32: UInt32
    var uint64: UInt64
    var str: String
    var date: Date
}

struct OptTypedModel: CBLCodable {
    var bool: Bool?
    var double: Double?
    var float: Float?
    var int: Int?
    var int8: Int8?
    var int16: Int16?
    var int32: Int32?
    var int64: Int64?
    var uint: UInt?
    var uint8: UInt8?
    var uint16: UInt16?
    var uint32: UInt32?
    var uint64: UInt64?
    var str: String?
    var date: Date?
}

struct Student: DocumentCodable {
    var document: MutableDocument?
    
    var name: String
    var dob: Date?
    var photo: Blob?
    var address: Address?
    var contacts: [Person]?

    enum CodingKeys: String, CodingKey {
        case name
        case dob
        case photo
        case address
        case contacts
    }
}
