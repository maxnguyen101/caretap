import ActivityKit
import SwiftUI
import WidgetKit

private struct BestNextStepEntry: TimelineEntry {
    let date: Date
    let snapshot: BestNextStepSnapshot
}

private struct TodaySnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: TodaySnapshotWidgetState
}

private struct BestNextStepProvider: TimelineProvider {
    private let source = WidgetSnapshotSource()

    func placeholder(in context: Context) -> BestNextStepEntry {
        BestNextStepEntry(date: .now, snapshot: source.bestNextStepPlaceholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (BestNextStepEntry) -> Void) {
        completion(BestNextStepEntry(date: .now, snapshot: source.bestNextStep()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BestNextStepEntry>) -> Void) {
        let entry = BestNextStepEntry(date: .now, snapshot: source.bestNextStep())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 30))))
    }
}

private struct TodaySnapshotProvider: TimelineProvider {
    private let source = WidgetSnapshotSource()

    func placeholder(in context: Context) -> TodaySnapshotEntry {
        TodaySnapshotEntry(date: .now, snapshot: source.todayPlaceholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaySnapshotEntry) -> Void) {
        completion(TodaySnapshotEntry(date: .now, snapshot: source.todaySnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySnapshotEntry>) -> Void) {
        let entry = TodaySnapshotEntry(date: .now, snapshot: source.todaySnapshot())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 30))))
    }
}

private struct WidgetSnapshotSource {
    private let fallback = PreviewHomeSnapshotService()
    private let store = CareTapWidgetSnapshotStore(bundle: .main)

    func bestNextStepPlaceholder() -> BestNextStepSnapshot {
        fallback.bestNextStepSnapshot()
    }

    func bestNextStep() -> BestNextStepSnapshot {
        (try? store.loadBestNextStep()) ?? fallback.bestNextStepSnapshot()
    }

    func todayPlaceholder() -> TodaySnapshotWidgetState {
        fallback.todaySnapshotWidgetState()
    }

    func todaySnapshot() -> TodaySnapshotWidgetState {
        (try? store.loadTodaySnapshot()) ?? fallback.todaySnapshotWidgetState()
    }
}

struct BestNextStepWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BestNextStepWidget", provider: BestNextStepProvider()) { entry in
            BestNextStepWidgetView(snapshot: entry.snapshot)
                .widgetURL(CareTapDeepLink.widgetURL(destination: .home))
                .containerBackground(CareTapTheme.canvas, for: .widget)
        }
        .configurationDisplayName("Best Next Step")
        .description("Shows the next check-in or item that matters most right now.")
        .supportedFamilies([.systemSmall])
    }
}

struct TodaySnapshotWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodaySnapshotWidget", provider: TodaySnapshotProvider()) { entry in
            TodaySnapshotWidgetView(snapshot: entry.snapshot)
                .widgetURL(CareTapDeepLink.widgetURL(destination: .workspace))
                .containerBackground(CareTapTheme.canvas, for: .widget)
        }
        .configurationDisplayName("Today Snapshot")
        .description("Summarizes today's progress and the next thing coming up.")
        .supportedFamilies([.systemMedium])
    }
}

struct CareTapDoseActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CareTapDoseActivityAttributes.self) { context in
            CareTapDoseActivityView(state: CareTapDoseActivityViewState(contentState: context.state))
                .activityBackgroundTint(CareTapTheme.canvas)
                .activitySystemActionForegroundColor(CareTapTheme.sage)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TapCare")
                            .font(CareTapTypography.micro)
                            .foregroundStyle(CareTapTheme.textTertiary)
                        Text(context.state.dueTime, style: .time)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textPrimary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CareTapStatusBadge(text: context.state.status.badgeText, tone: context.state.status.tone)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    CareTapDoseActivityView(state: CareTapDoseActivityViewState(contentState: context.state))
                }
            } compactLeading: {
                Image(systemName: "pills.fill")
                    .foregroundStyle(CareTapTheme.sage)
            } compactTrailing: {
                Text(context.state.dueTime, style: .time)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textPrimary)
            } minimal: {
                Image(systemName: "pills.fill")
            }
        }
    }
}

@main
struct CareTapWidgetBundle: WidgetBundle {
    var body: some Widget {
        BestNextStepWidget()
        TodaySnapshotWidget()
        CareTapDoseActivityWidget()
    }
}

#Preview("Small Widget", as: .systemSmall) {
    BestNextStepWidget()
} timeline: {
    BestNextStepEntry(date: .now, snapshot: PreviewHomeSnapshotService().bestNextStepSnapshot())
}

#Preview("Medium Widget", as: .systemMedium) {
    TodaySnapshotWidget()
} timeline: {
    TodaySnapshotEntry(date: .now, snapshot: PreviewHomeSnapshotService().todaySnapshotWidgetState())
}
