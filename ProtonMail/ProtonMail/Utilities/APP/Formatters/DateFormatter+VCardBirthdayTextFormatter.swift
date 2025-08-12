import Foundation

extension DateFormatter {

    static var vCardBirthdayTextFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: -3600)
        formatter.locale = LocaleEnvironment.locale()
        return formatter
    }

}
