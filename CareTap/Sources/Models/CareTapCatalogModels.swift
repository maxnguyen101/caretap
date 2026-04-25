import Foundation

struct CareTapCatalogItem: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let category: MedicationCategory
    let symbolName: String
    let tone: CareTapTone
    let aliases: [String]
    let defaultDosage: String?
    let defaultContainerKind: ContainerKind
    let defaultReminderLeadTimeMinutes: Int?
    let defaultTimeTitles: [String]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        category: MedicationCategory,
        symbolName: String,
        tone: CareTapTone,
        aliases: [String] = [],
        defaultDosage: String? = nil,
        defaultContainerKind: ContainerKind = .bottle,
        defaultReminderLeadTimeMinutes: Int? = nil,
        defaultTimeTitles: [String] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.symbolName = symbolName
        self.tone = tone
        self.aliases = aliases
        self.defaultDosage = defaultDosage
        self.defaultContainerKind = defaultContainerKind
        self.defaultReminderLeadTimeMinutes = defaultReminderLeadTimeMinutes
        self.defaultTimeTitles = defaultTimeTitles
    }
}
