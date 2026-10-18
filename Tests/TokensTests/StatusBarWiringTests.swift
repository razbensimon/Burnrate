import Foundation
import Testing
@testable import Tokens

@Test @MainActor func statusBarStoreUsesFormatter() {
    let suite = "com.burnrate.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    defer { defaults.removePersistentDomain(forName: suite) }

    let settings = SettingsStore(defaults: defaults, persistMembershipSecretInKeychain: false)
    let store = UsageStore(settings: settings, enableAnomalyAlerts: false)

    #expect(store.menuAmountText == "$—.——")
    #expect(store.menuAmountAccessibilityText == "Window spend $—.——")
    #expect(store.statusBarInput.spendIsPlaceholder == true)

    settings.statusBarShowsWindowSpend = false
    settings.statusBarShowsCursorModels = true
    #expect(store.menuAmountText == "—")
    #expect(store.menuAmountAccessibilityText == "Cursor models not loaded")

    let header = StatusBarFigures.header(store.statusBarInput)
    #expect(header.hero == "—")
    #expect(header.caption == "Cursor models used this cycle")
    #expect(header.showsTimelineSpendBelow == true)

    settings.statusBarShowsCursorModels = false
    #expect(store.menuAmountText == nil)
    let hiddenHeader = StatusBarFigures.header(store.statusBarInput)
    #expect(hiddenHeader.hero == "$—.——")
    #expect(hiddenHeader.showsTimelineSpendBelow == false)
}
