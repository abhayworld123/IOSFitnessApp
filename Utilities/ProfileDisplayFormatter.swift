import Foundation

enum ProfileDisplayFormatter {
    static func weight(kg: Double?, unit: WeightUnit?) -> String {
        guard let kg else { return "—" }
        let displayUnit = unit ?? .kg
        let display = WeightUnit.kg.convert(kg, to: displayUnit)
        let suffix = displayUnit == .kg ? "kg" : "lbs"
        return "\(Int(round(display))) \(suffix)"
    }

    static func height(cm: Double?, unit: HeightUnit?) -> String {
        guard let cm else { return "—" }
        let displayUnit = unit ?? .cm
        switch displayUnit {
        case .cm:
            return "\(Int(round(cm))) cm"
        case .ftIn:
            return displayUnit.formatHeight(cm)
        }
    }

    static func age(_ age: Int?) -> String {
        guard let age else { return "—" }
        return "\(age)"
    }
}
