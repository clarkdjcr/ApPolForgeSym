import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), incumbentEV: 210, challengerEV: 190, currentTurn: 12)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), incumbentEV: 242, challengerEV: 238, currentTurn: 15)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, incumbentEV: 242, challengerEV: 238, currentTurn: 15)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let incumbentEV: Int
    let challengerEV: Int
    let currentTurn: Int
}

struct PolForgeWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("POLFORGE '24")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.blue)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.incumbentEV)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("INCUMBENT")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(entry.challengerEV)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    Text("CHALLENGER")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(Double(entry.incumbentEV) / 538.0))
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geo.size.width * CGFloat(Double(538 - entry.incumbentEV - entry.challengerEV) / 538.0))
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geo.size.width * CGFloat(Double(entry.challengerEV) / 538.0))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
            
            Text("WEEK \(entry.currentTurn) STATUS")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct PolForgeWidget: Widget {
    let kind: String = "PolForgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PolForgeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("PolForge Tracker")
        .description("Track the path to 270 in real-time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview {
    PolForgeWidgetEntryView(entry: SimpleEntry(date: Date(), incumbentEV: 242, challengerEV: 238, currentTurn: 15))
}
