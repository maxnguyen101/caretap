import Foundation

enum SupabaseTransportError: Error {
    case missingConfiguration
    case invalidRequest
    case invalidResponse
    case unsupportedFilter
}

struct SupabaseConfiguration: Hashable {
    let projectURL: URL
    let apiKey: String
    let schema: String
    let universalLinkHost: String?

    init(projectURL: URL, apiKey: String, schema: String = "public", universalLinkHost: String? = nil) {
        self.projectURL = projectURL
        self.apiKey = apiKey
        self.schema = schema
        let trimmedHost = universalLinkHost?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.universalLinkHost = trimmedHost?.isEmpty == true ? nil : trimmedHost
    }
}

enum SupabaseFilterOperator: String, Hashable {
    case equal = "eq"
    case greaterThan = "gt"
    case greaterThanOrEqual = "gte"
    case lessThan = "lt"
    case lessThanOrEqual = "lte"
}

enum SupabaseFilterValue: Hashable {
    case string(String)
    case uuid(UUID)
    case date(Date)
    case int(Int)
    case double(Double)
    case bool(Bool)

    fileprivate func queryValue(using formatter: ISO8601DateFormatter) -> String {
        switch self {
        case let .string(value):
            return value
        case let .uuid(value):
            return value.uuidString
        case let .date(value):
            return formatter.string(from: value)
        case let .int(value):
            return String(value)
        case let .double(value):
            return String(value)
        case let .bool(value):
            return value ? "true" : "false"
        }
    }
}

struct SupabaseFilter: Hashable {
    let column: String
    let `operator`: SupabaseFilterOperator
    let value: SupabaseFilterValue
}

struct SupabaseSort: Hashable {
    let column: String
    let ascending: Bool
}

protocol SupabaseTransporting: Sendable {
    func select<Row: Decodable>(
        from table: CareTapSupabaseTable,
        filters: [SupabaseFilter],
        orderBy: SupabaseSort?,
        limit: Int?
    ) async throws -> [Row]

    func upsert<Row: Encodable & Decodable>(
        _ rows: [Row],
        into table: CareTapSupabaseTable,
        onConflict: [String]
    ) async throws -> [Row]
}

protocol LocalSupabaseCachingTransport: SupabaseTransporting, Sendable {
    func seed(_ payload: CareTapSyncBatchPayload) throws
}

enum CareTapSupabaseJSON {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static var iso8601: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

struct URLSessionSupabaseTransport: SupabaseTransporting {
    let configuration: SupabaseConfiguration
    let session: URLSession
    let authSessionStore: (any CareTapAuthSessionPersisting)?

    init(
        configuration: SupabaseConfiguration,
        authSessionStore: (any CareTapAuthSessionPersisting)? = nil,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.authSessionStore = authSessionStore
        self.session = session
    }

    func select<Row: Decodable>(
        from table: CareTapSupabaseTable,
        filters: [SupabaseFilter],
        orderBy: SupabaseSort? = nil,
        limit: Int? = nil
    ) async throws -> [Row] {
        var components = URLComponents(url: configuration.projectURL.appending(path: "/rest/v1/\(table.rawValue)"), resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem(name: "select", value: "*")]

        queryItems.append(contentsOf: filters.map { filter in
            URLQueryItem(
                name: filter.column,
                value: "\(filter.operator.rawValue).\(filter.value.queryValue(using: CareTapSupabaseJSON.iso8601))"
            )
        })

        if let orderBy {
            let direction = orderBy.ascending ? "asc" : "desc"
            queryItems.append(URLQueryItem(name: "order", value: "\(orderBy.column).\(direction)"))
        }

        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw SupabaseTransportError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authorizationToken())", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.schema, forHTTPHeaderField: "Accept-Profile")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw SupabaseTransportError.invalidResponse
        }

        return try CareTapSupabaseJSON.decoder.decode([Row].self, from: data)
    }

    func upsert<Row: Encodable & Decodable>(
        _ rows: [Row],
        into table: CareTapSupabaseTable,
        onConflict: [String] = ["id"]
    ) async throws -> [Row] {
        guard !rows.isEmpty else {
            return []
        }

        var components = URLComponents(url: configuration.projectURL.appending(path: "/rest/v1/\(table.rawValue)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "on_conflict", value: onConflict.joined(separator: ","))
        ]

        guard let url = components?.url else {
            throw SupabaseTransportError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try CareTapSupabaseJSON.encoder.encode(rows)
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authorizationToken())", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.schema, forHTTPHeaderField: "Content-Profile")
        request.setValue(configuration.schema, forHTTPHeaderField: "Accept-Profile")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw SupabaseTransportError.invalidResponse
        }

        return try CareTapSupabaseJSON.decoder.decode([Row].self, from: data)
    }

    func rpc<Body: Encodable, Response: Decodable>(
        function: String,
        body: Body
    ) async throws -> Response {
        let url = configuration.projectURL.appending(path: "/rest/v1/rpc/\(function)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try CareTapSupabaseJSON.encoder.encode(body)
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authorizationToken())", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.schema, forHTTPHeaderField: "Content-Profile")
        request.setValue(configuration.schema, forHTTPHeaderField: "Accept-Profile")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw SupabaseTransportError.invalidResponse
        }

        return try CareTapSupabaseJSON.decoder.decode(Response.self, from: data)
    }

    private func authorizationToken() -> String {
        if let accessToken = try? authSessionStore?.loadAuthSession()?.accessToken,
           !accessToken.isEmpty {
            return accessToken
        }

        return configuration.apiKey
    }
}

final class InMemorySupabaseTransport: LocalSupabaseCachingTransport, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [CareTapSupabaseTable: [Data]] = [:]

    func select<Row: Decodable>(
        from table: CareTapSupabaseTable,
        filters: [SupabaseFilter],
        orderBy: SupabaseSort? = nil,
        limit: Int? = nil
    ) async throws -> [Row] {
        let snapshot = lock.withLock { storage[table, default: []] }

        let entries = try snapshot.map { data in
            (
                row: try CareTapSupabaseJSON.decoder.decode(Row.self, from: data),
                object: try Self.jsonObject(from: data)
            )
        }

        let filtered = try entries.filter { entry in
            try Self.matches(filters: filters, object: entry.object)
        }

        let sorted = try Self.sorted(entries: filtered, using: orderBy)
        if let limit {
            return Array(sorted.prefix(limit)).map(\.row)
        }

        return sorted.map(\.row)
    }

    func upsert<Row: Encodable & Decodable>(
        _ rows: [Row],
        into table: CareTapSupabaseTable,
        onConflict: [String] = ["id"]
    ) async throws -> [Row] {
        try performUpsert(rows, into: table, onConflict: onConflict)
    }

    private func performUpsert<Row: Encodable & Decodable>(
        _ rows: [Row],
        into table: CareTapSupabaseTable,
        onConflict: [String]
    ) throws -> [Row] {
        guard !rows.isEmpty else {
            return []
        }

        let snapshot = lock.withLock { storage[table, default: []] }

        var existing = try snapshot.map {
            try CareTapSupabaseJSON.decoder.decode(Row.self, from: $0)
        }

        for row in rows {
            let object = try Self.jsonObject(for: row)
            guard let matchKey = onConflict.first,
                  let matchValue = object[matchKey] else {
                throw SupabaseTransportError.invalidRequest
            }

            if let index = try existing.firstIndex(where: { try Self.fieldValue(named: matchKey, from: $0) == matchValue }) {
                existing[index] = row
            } else {
                existing.append(row)
            }
        }

        let encoded = try existing.map { try CareTapSupabaseJSON.encoder.encode($0) }
        lock.withLock {
            storage[table] = encoded
        }
        return rows
    }

    func seed(_ payload: CareTapSyncBatchPayload) throws {
        _ = try performUpsert(payload.users, into: .users, onConflict: ["id"])
        _ = try performUpsert(payload.careProfiles, into: .careProfiles, onConflict: ["id"])
        _ = try performUpsert(payload.careRelationships, into: .careRelationships, onConflict: ["id"])
        _ = try performUpsert(payload.medications, into: .medications, onConflict: ["id"])
        _ = try performUpsert(payload.scheduleRules, into: .scheduleRules, onConflict: ["id"])
        _ = try performUpsert(payload.doseOccurrences, into: .doseOccurrences, onConflict: ["id"])
        _ = try performUpsert(payload.doseLogs, into: .doseLogs, onConflict: ["id"])
        _ = try performUpsert(payload.nfcTags, into: .nfcTags, onConflict: ["id"])
        _ = try performUpsert(payload.reminderPreferences, into: .reminderPreferences, onConflict: ["id"])
        _ = try performUpsert(payload.alertPolicies, into: .alertPolicies, onConflict: ["id"])
        _ = try performUpsert(payload.refillStates, into: .refillStates, onConflict: ["id"])
        _ = try performUpsert(payload.invitations, into: .invitations, onConflict: ["id"])
    }

    func snapshot() throws -> CareTapSyncBatchPayload {
        CareTapSyncBatchPayload(
            users: try decodedRows(for: .users),
            careProfiles: try decodedRows(for: .careProfiles),
            careRelationships: try decodedRows(for: .careRelationships),
            medications: try decodedRows(for: .medications),
            scheduleRules: try decodedRows(for: .scheduleRules),
            doseOccurrences: try decodedRows(for: .doseOccurrences),
            doseLogs: try decodedRows(for: .doseLogs),
            nfcTags: try decodedRows(for: .nfcTags),
            reminderPreferences: try decodedRows(for: .reminderPreferences),
            alertPolicies: try decodedRows(for: .alertPolicies),
            refillStates: try decodedRows(for: .refillStates),
            invitations: try decodedRows(for: .invitations)
        )
    }

    private func decodedRows<Row: Decodable>(for table: CareTapSupabaseTable) throws -> [Row] {
        let snapshot = lock.withLock {
            storage[table, default: []]
        }

        return try snapshot.map { data in
            try CareTapSupabaseJSON.decoder.decode(Row.self, from: data)
        }
    }

    private static func jsonObject<Row: Encodable>(for row: Row) throws -> [String: AnyHashable] {
        let data = try CareTapSupabaseJSON.encoder.encode(row)
        return try jsonObject(from: data)
    }

    private static func jsonObject(from data: Data) throws -> [String: AnyHashable] {
        let raw = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = raw as? [String: Any] else {
            throw SupabaseTransportError.invalidResponse
        }

        return dictionary.reduce(into: [:]) { partialResult, pair in
            if let hashable = pair.value as? AnyHashable {
                partialResult[pair.key] = hashable
            }
        }
    }

    private static func fieldValue<Row: Encodable>(named key: String, from row: Row) throws -> AnyHashable {
        let object = try jsonObject(for: row)
        guard let value = object[key] else {
            throw SupabaseTransportError.unsupportedFilter
        }

        return value
    }

    private static func matches(filters: [SupabaseFilter], object: [String: AnyHashable]) throws -> Bool {
        try filters.allSatisfy { filter in
            guard let value = object[filter.column] else {
                return false
            }

            let expected = filter.value.queryValue(using: CareTapSupabaseJSON.iso8601)
            switch filter.operator {
            case .equal:
                return String(describing: value) == expected
            case .greaterThan:
                return try compare(value, expected, using: >)
            case .greaterThanOrEqual:
                return try compare(value, expected, using: >=)
            case .lessThan:
                return try compare(value, expected, using: <)
            case .lessThanOrEqual:
                return try compare(value, expected, using: <=)
            }
        }
    }

    private static func compare(
        _ value: AnyHashable,
        _ expected: String,
        using stringComparator: (String, String) -> Bool
    ) throws -> Bool {
        if let number = value as? NSNumber {
            return stringComparator(number.stringValue, expected)
        }

        if let string = value as? String {
            return stringComparator(string, expected)
        }

        throw SupabaseTransportError.unsupportedFilter
    }

    private static func sorted<Row>(
        entries: [(row: Row, object: [String: AnyHashable])],
        using sort: SupabaseSort?
    ) throws -> [(row: Row, object: [String: AnyHashable])] {
        guard let sort else {
            return entries
        }

        return entries.sorted { left, right in
            guard let leftValue = left.object[sort.column],
                  let rightValue = right.object[sort.column] else {
                return false
            }
            let lhs = String(describing: leftValue)
            let rhs = String(describing: rightValue)
            return sort.ascending ? lhs < rhs : lhs > rhs
        }
    }
}

final class PersistentSupabaseTransport: LocalSupabaseCachingTransport, @unchecked Sendable {
    private let backing = InMemorySupabaseTransport()
    private let store: CareTapBackendDiskStore

    init(store: CareTapBackendDiskStore) throws {
        self.store = store
        if let cachedPayload = try store.loadCache() {
            try backing.seed(cachedPayload)
        }
    }

    func select<Row: Decodable>(
        from table: CareTapSupabaseTable,
        filters: [SupabaseFilter],
        orderBy: SupabaseSort?,
        limit: Int?
    ) async throws -> [Row] {
        try await backing.select(from: table, filters: filters, orderBy: orderBy, limit: limit)
    }

    func upsert<Row: Encodable & Decodable>(
        _ rows: [Row],
        into table: CareTapSupabaseTable,
        onConflict: [String]
    ) async throws -> [Row] {
        let storedRows = try await backing.upsert(rows, into: table, onConflict: onConflict)
        try persistSnapshot()
        return storedRows
    }

    func seed(_ payload: CareTapSyncBatchPayload) throws {
        try backing.seed(payload)
        try persistSnapshot()
    }

    private func persistSnapshot() throws {
        try store.saveCache(backing.snapshot())
    }
}
