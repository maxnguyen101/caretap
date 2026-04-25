import Foundation

struct CareTapBundledMedicationCatalog {
    private let items: [CareTapCatalogItem]

    init(bundle: Bundle = .main) {
        items = Self.loadItems(from: bundle) ?? Self.fallbackItems
    }

    func allSuggestions(limit: Int = 14) -> [MedicationSuggestionState] {
        items.prefix(limit).map(Self.makeSuggestion)
    }

    func suggestions(matching query: String, limit: Int = 14) -> [MedicationSuggestionState] {
        let normalizedQuery = Self.normalized(query)
        guard !normalizedQuery.isEmpty else {
            return allSuggestions(limit: limit)
        }

        let matches = items
            .map { item in (item: item, score: score(item: item, normalizedQuery: normalizedQuery)) }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
                }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map(\.item)

        return matches.map(Self.makeSuggestion)
    }

    func item(for suggestionID: UUID?) -> CareTapCatalogItem? {
        guard let suggestionID else { return nil }
        return items.first { $0.id == suggestionID }
    }

    private func score(item: CareTapCatalogItem, normalizedQuery: String) -> Int {
        let title = Self.normalized(item.title)
        let subtitle = Self.normalized(item.subtitle)
        let aliases = item.aliases.map(Self.normalized)

        if title == normalizedQuery || aliases.contains(normalizedQuery) {
            return 120
        }

        var score = 0

        if title.hasPrefix(normalizedQuery) {
            score += 100
        } else if title.contains(normalizedQuery) {
            score += 80
        }

        if subtitle.contains(normalizedQuery) {
            score += 35
        }

        if aliases.contains(where: { $0.hasPrefix(normalizedQuery) }) {
            score += 70
        } else if aliases.contains(where: { $0.contains(normalizedQuery) }) {
            score += 50
        }

        let queryTokens = Set(normalizedQuery.split(separator: " ").map(String.init))
        if !queryTokens.isEmpty {
            let itemTokens = Set((title + " " + subtitle + " " + aliases.joined(separator: " "))
                .split(separator: " ")
                .map(String.init))
            score += queryTokens.intersection(itemTokens).count * 18
        }

        return score
    }

    private static func makeSuggestion(from item: CareTapCatalogItem) -> MedicationSuggestionState {
        MedicationSuggestionState(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            category: item.category,
            symbolName: item.symbolName,
            tone: item.tone,
            aliases: item.aliases,
            defaultDosage: item.defaultDosage,
            defaultContainerKind: item.defaultContainerKind,
            defaultReminderLeadTimeMinutes: item.defaultReminderLeadTimeMinutes,
            defaultTimeTitles: item.defaultTimeTitles
        )
    }

    private static func loadItems(from bundle: Bundle) -> [CareTapCatalogItem]? {
        guard let url = bundle.url(forResource: "medication_catalog", withExtension: "json", subdirectory: "Catalog") else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode([CareTapCatalogItem].self, from: data)
    }

    private static func normalized(_ string: String) -> String {
        let folded = string
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let pieces = folded
            .replacingOccurrences(of: "&", with: " and ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map(singularizedToken)

        return pieces.joined(separator: " ")
    }

    private static func singularizedToken(_ token: String) -> String {
        guard token.count > 3 else { return token }
        if token.hasSuffix("ies") {
            return String(token.dropLast(3)) + "y"
        }
        if token.hasSuffix("es") {
            return String(token.dropLast(2))
        }
        if token.hasSuffix("s") {
            return String(token.dropLast())
        }
        return token
    }

    private static let fallbackItems: [CareTapCatalogItem] = [
        CareTapCatalogItem(
            title: "Lisinopril",
            subtitle: "Blood pressure",
            category: .prescription,
            symbolName: "heart.text.square.fill",
            tone: .success,
            aliases: ["prinivil", "zestril"],
            defaultDosage: "10 mg",
            defaultContainerKind: .bottle,
            defaultReminderLeadTimeMinutes: 15,
            defaultTimeTitles: ["Morning"]
        ),
        CareTapCatalogItem(
            title: "Vitamin D",
            subtitle: "Daily supplement",
            category: .supplement,
            symbolName: "sun.max.circle.fill",
            tone: .warm,
            aliases: ["vitamin d3", "cholecalciferol"],
            defaultDosage: "1 softgel",
            defaultContainerKind: .bottle,
            defaultReminderLeadTimeMinutes: 0,
            defaultTimeTitles: ["Morning"]
        ),
        CareTapCatalogItem(
            title: "Creatine",
            subtitle: "Workout supplement",
            category: .supplement,
            symbolName: "figure.strengthtraining.traditional",
            tone: .mist,
            aliases: ["creatine monohydrate"],
            defaultDosage: "5 g",
            defaultContainerKind: .packet,
            defaultReminderLeadTimeMinutes: 0,
            defaultTimeTitles: ["Noon"]
        ),
        CareTapCatalogItem(
            title: "Protein Powder",
            subtitle: "Post-workout routine",
            category: .supplement,
            symbolName: "dumbbell.fill",
            tone: .neutral,
            aliases: ["whey", "protein shake"],
            defaultDosage: "1 scoop",
            defaultContainerKind: .packet,
            defaultReminderLeadTimeMinutes: 0,
            defaultTimeTitles: ["Evening"]
        )
    ]
}
