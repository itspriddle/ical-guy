import Foundation

func jsonEncode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if isatty(fileno(stdout)) != 0 {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    } else {
        encoder.outputFormatting = [.sortedKeys]
    }
    return try encoder.encode(value)
}
