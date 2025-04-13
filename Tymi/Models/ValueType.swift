import Foundation

enum ValueType: Codable, Equatable {
    case count(Int32)
    case time(Double)
    
    private enum CodingKeys: String, CodingKey {
        case type, countValue, timeValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "count":
            let value = try container.decode(Int32.self, forKey: .countValue)
            self = .count(value)
        case "time":
            let value = try container.decode(Double.self, forKey: .timeValue)
            self = .time(value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid value type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .count(let value):
            try container.encode("count", forKey: .type)
            try container.encode(value, forKey: .countValue)
        case .time(let value):
            try container.encode("time", forKey: .type)
            try container.encode(value, forKey: .timeValue)
        }
    }
    
    var doubleValue: Double {
        switch self {
        case .count(let value): return Double(value)
        case .time(let value): return value
        }
    }
    
    static func fromDouble(_ value: Double, type: HabitType) -> ValueType {
        switch type {
        case .count:
            return .count(Int32(value))
        case .time:
            return .time(value)
        }
    }
} 