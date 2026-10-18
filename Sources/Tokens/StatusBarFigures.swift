import Foundation

enum StatusBarFigures {
    struct Input: Equatable, Sendable {
        var showsWindowSpend: Bool
        var showsCursorModels: Bool
        var showsOtherModels: Bool
        var windowDollars: Double
        var spendIsPlaceholder: Bool
        var cursorModelsPercent: Double?
        var otherModelsPercent: Double?

        init(
            showsWindowSpend: Bool,
            showsCursorModels: Bool = false,
            showsOtherModels: Bool = false,
            windowDollars: Double = 12.40,
            spendIsPlaceholder: Bool = false,
            cursorModelsPercent: Double? = nil,
            otherModelsPercent: Double? = nil
        ) {
            self.showsWindowSpend = showsWindowSpend
            self.showsCursorModels = showsCursorModels
            self.showsOtherModels = showsOtherModels
            self.windowDollars = windowDollars
            self.spendIsPlaceholder = spendIsPlaceholder
            self.cursorModelsPercent = cursorModelsPercent
            self.otherModelsPercent = otherModelsPercent
        }
    }

    struct Header: Equatable, Sendable {
        var hero: String
        var companions: [String]
        var caption: String?
        var showsTimelineSpendBelow: Bool
        var timelineSpend: String
        var accessibilityLabel: String
    }

    static func statusText(_ input: Input) -> String? {
        let flags = Flags(input)
        guard flags.showsAny else { return nil }
        return tokens(input, flags: flags).joined(separator: " · ")
    }

    static func accessibilityLabel(_ input: Input) -> String? {
        let flags = Flags(input)
        guard flags.showsAny else { return nil }
        return labeled(input, flags: flags)
    }

    static func header(_ input: Input) -> Header {
        var flags = Flags(input)
        if !flags.showsAny {
            flags.spend = true
        }
        let parts = tokens(input, flags: flags)
        return Header(
            hero: parts[0],
            companions: Array(parts.dropFirst()),
            caption: poolCaption(flags),
            showsTimelineSpendBelow: !flags.spend,
            timelineSpend: spendText(input),
            accessibilityLabel: labeled(input, flags: flags)
        )
    }

    private struct Flags: Equatable {
        var spend: Bool
        var cursor: Bool
        var other: Bool

        var showsAny: Bool { spend || cursor || other }

        init(_ input: Input) {
            spend = input.showsWindowSpend
            cursor = input.showsCursorModels
            other = input.showsOtherModels
        }
    }

    private static func tokens(_ input: Input, flags: Flags) -> [String] {
        var parts: [String] = []
        let bothPercents = flags.cursor && flags.other
        if flags.spend {
            parts.append(spendText(input))
        }
        if flags.cursor {
            parts.append(percentToken(input.cursorModelsPercent, prefix: bothPercents ? "C" : nil))
        }
        if flags.other {
            parts.append(percentToken(input.otherModelsPercent, prefix: bothPercents ? "O" : nil))
        }
        return parts
    }

    private static func spendText(_ input: Input) -> String {
        if input.spendIsPlaceholder { return "$—.——" }
        return MoneyFormat.dollars(input.windowDollars)
    }

    private static func percentToken(_ percent: Double?, prefix: String?) -> String {
        let number = percent.map { "\(IncludedPools.displayPercent($0))%" } ?? "—"
        guard let prefix else { return number }
        return "\(prefix) \(number)"
    }

    private static func poolCaption(_ flags: Flags) -> String? {
        switch (flags.cursor, flags.other) {
        case (true, true):
            "Cursor models used this cycle · Other models used this cycle"
        case (true, false):
            "Cursor models used this cycle"
        case (false, true):
            "Other models used this cycle"
        case (false, false):
            nil
        }
    }

    private static func labeled(_ input: Input, flags: Flags) -> String {
        var parts: [String] = []
        if flags.spend {
            parts.append("Window spend \(spendText(input))")
        }
        if flags.cursor {
            parts.append(percentAccess("Cursor models", input.cursorModelsPercent))
        }
        if flags.other {
            parts.append(percentAccess("Other models", input.otherModelsPercent))
        }
        return parts.joined(separator: ", ")
    }

    private static func percentAccess(_ name: String, _ percent: Double?) -> String {
        guard let percent else { return "\(name) not loaded" }
        return "\(name) \(IncludedPools.displayPercent(percent)) percent used"
    }
}
