import Foundation

struct HabitState: Codable {
    let habitId: UUID
    let currentValue: ValueType
    let isCompleted: Bool
    let lastUpdate: Date
    let isPlaying: Bool
    let startTime: Date?
    let habitType: HabitType
    let lastActionTimestamp: Date?
    let lastActionType: ProgressAction.ActionType?
    let lastActionAmount: Double?
    let totalAddedAmount: Double
    let undoneAmount: Double
    
    private enum CodingKeys: String, CodingKey {
        case habitId, currentValue, isCompleted, lastUpdate, isPlaying, startTime
        case habitType, lastActionTimestamp, lastActionType, lastActionAmount
        case totalAddedAmount, undoneAmount
    }
    
    init(
        habitId: UUID,
        currentValue: ValueType,
        isCompleted: Bool,
        lastUpdate: Date,
        isPlaying: Bool,
        startTime: Date?,
        habitType: HabitType,
        lastActionTimestamp: Date?,
        lastActionType: ProgressAction.ActionType?,
        lastActionAmount: Double?,
        totalAddedAmount: Double,
        undoneAmount: Double
    ) {
        self.habitId = habitId
        self.currentValue = currentValue
        self.isCompleted = isCompleted
        self.lastUpdate = lastUpdate
        self.isPlaying = isPlaying
        self.startTime = startTime
        self.habitType = habitType
        self.lastActionTimestamp = lastActionTimestamp
        self.lastActionType = lastActionType
        self.lastActionAmount = lastActionAmount
        self.totalAddedAmount = totalAddedAmount
        self.undoneAmount = undoneAmount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        currentValue = try container.decode(ValueType.self, forKey: .currentValue)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        lastUpdate = try container.decode(Date.self, forKey: .lastUpdate)
        isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        habitType = try container.decode(HabitType.self, forKey: .habitType)
        lastActionTimestamp = try container.decodeIfPresent(Date.self, forKey: .lastActionTimestamp)
        lastActionType = try container.decodeIfPresent(ProgressAction.ActionType.self, forKey: .lastActionType)
        lastActionAmount = try container.decodeIfPresent(Double.self, forKey: .lastActionAmount)
        totalAddedAmount = try container.decode(Double.self, forKey: .totalAddedAmount)
        undoneAmount = try container.decode(Double.self, forKey: .undoneAmount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(habitId, forKey: .habitId)
        try container.encode(currentValue, forKey: .currentValue)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(lastUpdate, forKey: .lastUpdate)
        try container.encode(isPlaying, forKey: .isPlaying)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encode(habitType, forKey: .habitType)
        try container.encodeIfPresent(lastActionTimestamp, forKey: .lastActionTimestamp)
        try container.encodeIfPresent(lastActionType, forKey: .lastActionType)
        try container.encodeIfPresent(lastActionAmount, forKey: .lastActionAmount)
        try container.encode(totalAddedAmount, forKey: .totalAddedAmount)
        try container.encode(undoneAmount, forKey: .undoneAmount)
    }
} 