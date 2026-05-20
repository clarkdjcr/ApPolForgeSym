#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI

struct ElectionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes during the activity
        var incumbentEV: Int
        var challengerEV: Int
        var statusMessage: String
    }

    // Fixed properties that don't change
    var raceName: String
}

@available(iOS 16.1, *)
struct ElectionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ElectionAttributes.self) { context in
            // Lock screen/banner UI
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(context.state.incumbentEV)")
                            .font(.title)
                            .bold()
                            .foregroundColor(.blue)
                        Text("Incumbent")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("270 TO WIN")
                            .font(.system(size: 10, weight: .black))
                        Text(context.state.statusMessage)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(context.state.challengerEV)")
                            .font(.title)
                            .bold()
                            .foregroundColor(.red)
                        Text("Challenger")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.incumbentEV)")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.challengerEV)")
                        .font(.title)
                        .foregroundColor(.red)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.statusMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
            } compactLeading: {
                Text("I: \(context.state.incumbentEV)")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("C: \(context.state.challengerEV)")
                    .foregroundColor(.red)
            } minimal: {
                Image(systemName: "flag.fill")
                    .foregroundColor(.blue)
            }
            .keylineTint(Color.blue)
        }
    }
}
#endif
