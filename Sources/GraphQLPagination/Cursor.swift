import Foundation

public struct Cursor: RawRepresentable, Hashable, Sendable {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension Cursor: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension Cursor: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.rawValue = String(describing: value)
    }
}

extension Cursor {
    public init(intValue: Int) {
        self.rawValue = String(intValue)
    }
    public func intValue() -> Int? {
        return Int(self.rawValue)
    }
}

extension Cursor: CustomStringConvertible {
    public var description: String {
        self.rawValue.encodeBase64()
    }
}

extension Cursor: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue.encodeBase64())
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard
            let data = Data(base64Encoded: value),
            let string = String(data: data, encoding: .utf8)
        else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cursor was invalid: \(value)"
            )
        }
        self.rawValue = string
    }
}

extension String {
    func encodeBase64() -> String {
        Data(self.utf8).base64EncodedString()
    }
    func decodeBase64() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
