//
//  BoardingPassKit+JulianDate.swift
//  BoardingPassKit
//

import Foundation

public enum JulianDateError: Error, LocalizedError {
    case invalidDayOfYear(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidDayOfYear(let day):
            return "Invalid Julian day of year: \(day)"
        }
    }
}

public enum JulianDateConverter {

    private static let inferenceThresholdDays = 183

    public static func toCalendarDate(dayOfYear: Int, year: Int, calendar: Calendar = .current) throws -> Date {
        try validate(dayOfYear: dayOfYear, year: year, calendar: calendar)
        var components = DateComponents()
        components.year = year
        components.day = 1
        components.month = 1
        guard let start = calendar.date(from: components),
              let date = calendar.date(byAdding: .day, value: dayOfYear - 1, to: start)
        else { throw JulianDateError.invalidDayOfYear(dayOfYear) }
        return date
    }

    public static func toCalendarDate(dayOfYear: Int, relativeTo reference: Date = Date(), calendar: Calendar = .current) throws -> Date {
        let refYear = calendar.component(.year, from: reference)
        try validate(dayOfYear: dayOfYear, year: refYear, calendar: calendar)

        var candidate = try toCalendarDate(dayOfYear: dayOfYear, year: refYear, calendar: calendar)
        let diffDays = calendar.dateComponents([.day], from: reference, to: candidate).day ?? 0

        if diffDays < -inferenceThresholdDays {
            let nextYear = refYear + 1
            try validate(dayOfYear: dayOfYear, year: nextYear, calendar: calendar)
            candidate = try toCalendarDate(dayOfYear: dayOfYear, year: nextYear, calendar: calendar)
        } else if diffDays > inferenceThresholdDays {
            let previousYear = refYear - 1
            try validate(dayOfYear: dayOfYear, year: previousYear, calendar: calendar)
            candidate = try toCalendarDate(dayOfYear: dayOfYear, year: previousYear, calendar: calendar)
        }

        return candidate
    }

    private static func validate(dayOfYear: Int, year: Int, calendar: Calendar) throws {
        let maxDay = maxDayOfYear(year, calendar: calendar)
        guard dayOfYear >= 1, dayOfYear <= maxDay else {
            throw JulianDateError.invalidDayOfYear(dayOfYear)
        }
    }

    private static func maxDayOfYear(_ year: Int, calendar: Calendar) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = 12
        components.day = 31
        guard let endOfYear = calendar.date(from: components) else { return 365 }
        return calendar.ordinality(of: .day, in: .year, for: endOfYear) ?? 365
    }
}

public extension BoardingPassLeg {

    func flightDate(relativeTo reference: Date = Date(), calendar: Calendar = .current) -> Date? {
        try? JulianDateConverter.toCalendarDate(dayOfYear: julianDate, relativeTo: reference, calendar: calendar)
    }

    func flightDate(year: Int, calendar: Calendar = .current) -> Date? {
        try? JulianDateConverter.toCalendarDate(dayOfYear: julianDate, year: year, calendar: calendar)
    }
}
