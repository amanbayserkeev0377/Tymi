import Foundation

struct ProgressAction: Codable {
    let oldValue: ValueType
    let newValue: ValueType
    let type: ActionType
    let timestamp: Date
    let addedAmount: Double?
    
    private enum CodingKeys: String, CodingKey {
        case oldValue, newValue, type, timestamp, addedAmount
    }
    
    init(oldValue: ValueType, newValue: ValueType, type: ActionType, timestamp: Date, addedAmount: Double?) {
        self.oldValue = oldValue
        self.newValue = newValue
        self.type = type
        self.timestamp = timestamp
        self.addedAmount = addedAmount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        oldValue = try container.decode(ValueType.self, forKey: .oldValue)
        newValue = try container.decode(ValueType.self, forKey: .newValue)
        type = try container.decode(ActionType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        addedAmount = try container.decodeIfPresent(Double.self, forKey: .addedAmount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(oldValue, forKey: .oldValue)
        try container.encode(newValue, forKey: .newValue)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(addedAmount, forKey: .addedAmount)
    }
    
    enum ActionType: Codable, Equatable {
        case increment(amount: Double)
        case manualInput
        case reset
        
        private enum CodingKeys: String, CodingKey {
            case type, amount
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "increment":
                let amount = try container.decode(Double.self, forKey: .amount)
                self = .increment(amount: amount)
            case "manualInput":
                self = .manualInput
            case "reset":
                self = .reset
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid action type")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .increment(let amount):
                try container.encode("increment", forKey: .type)
                try container.encode(amount, forKey: .amount)
            case .manualInput:
                try container.encode("manualInput", forKey: .type)
            case .reset:
                try container.encode("reset", forKey: .type)
            }
        }
    }
} 