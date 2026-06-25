import SwiftUI
import Charts
import BestEffortsCore

// MARK: - Root

struct BestEffortsHomeView: View {
    @StateObject private var vm = BestEffortsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isFinished {
                    BestEffortsDashboardView(vm: vm)
                } else {
                    BestEffortsSetupView(vm: vm)
                }
            }
            .navigationTitle("Best Efforts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}

// MARK: - Setup

struct BestEffortsSetupView: View {
    @ObservedObject var vm: BestEffortsViewModel

    var body: some View {
        List {
            Section {
                Text("Watch four institutions — the Principal, Congress, the Courts, and the Press — interact over many terms. No player decisions are available yet; this is a parameter sandbox where you adjust the dials and observe systemic outcomes.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section("Simulation Scale") {
                LabeledContent("Max Terms") {
                    Stepper("\(vm.config.maxTerms)", value: $vm.config.maxTerms, in: 1...100)
                }
                LabeledContent("Turns Per Term") {
                    Stepper("\(vm.config.turnsPerTerm)", value: $vm.config.turnsPerTerm, in: 4...20)
                }
            }

            Section("Principal Behavior") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Violation Chance")
                        Spacer()
                        Text(vm.config.baseViolateChance, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $vm.config.baseViolateChance, in: 0.05...0.95, step: 0.05)
                        .tint(.red)
                }
            }

            Section("Fourth Estate") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Report Chance")
                        Spacer()
                        Text(vm.config.reportChance, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $vm.config.reportChance, in: 0.05...0.95, step: 0.05)
                        .tint(.blue)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Realignment Trust Threshold")
                        Spacer()
                        Text("\(vm.config.realignmentThreshold)")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(vm.config.realignmentThreshold) },
                            set: { vm.config.realignmentThreshold = Int($0) }
                        ),
                        in: 40...95, step: 5
                    )
                    .tint(.green)
                }
            }

            Section("Seed") {
                HStack {
                    TextField("Seed (integer)", text: $vm.seedText)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    Button("Random") {
                        vm.randomizeSeed()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Section {
                Button {
                    vm.run()
                } label: {
                    if vm.isRunning {
                        HStack {
                            ProgressView()
                            Text("Running…")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Run Simulation")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(vm.isRunning)
            }
        }
    }
}

// MARK: - Dashboard

struct BestEffortsDashboardView: View {
    @ObservedObject var vm: BestEffortsViewModel

    var finalState: BestEffortsCore.GameState? { vm.result?.finalState }

    var body: some View {
        List {
            // Outcome banner
            Section {
                HStack(spacing: 12) {
                    Image(systemName: vm.outcomeIsFourthEstateWin ? "checkmark.seal.fill" : "clock.fill")
                        .font(.title2)
                        .foregroundStyle(vm.outcomeIsFourthEstateWin ? .green : .orange)
                    Text(vm.outcomeText)
                        .font(.headline)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(vm.outcomeIsFourthEstateWin ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                        .padding(4)
                )
            }

            // Final metrics
            if let state = finalState {
                Section("Final Metrics") {
                    MetricGaugeRow(label: "Approval", value: state.approval, color: .orange)
                    MetricGaugeRow(label: "Legitimacy", value: state.legitimacy, color: .purple)
                    MetricGaugeRow(label: "Trust", value: state.trust, color: .blue)
                    MetricGaugeRow(label: "Popularity", value: state.popularity, color: .green)
                    HStack {
                        Text("Power Accumulated")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(state.power)")
                            .fontWeight(.semibold)
                            .foregroundStyle(state.power > 0 ? .red : .primary)
                    }
                    HStack {
                        Text("Realignments")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(state.realignments)")
                            .fontWeight(.semibold)
                            .foregroundStyle(state.realignments > 0 ? .green : .secondary)
                    }
                }
            }

            // Trend chart
            if vm.history.count >= 2 {
                Section("Metric Trends") {
                    BEMetricTrendChart(history: vm.history)
                        .frame(height: 200)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }

            // Action buttons
            Section {
                Button("Run Again (Same Config)") {
                    vm.reset()
                    vm.randomizeSeed()
                    vm.run()
                }

                Button("New Configuration") {
                    vm.reset()
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Metric Gauge Row

private struct MetricGaugeRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(value)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            ProgressView(value: Double(value), total: 100)
                .tint(color)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Trend Chart

private struct MetricDataPoint: Identifiable {
    let id = UUID()
    let turn: Int
    let metric: String
    let value: Int
}

struct BEMetricTrendChart: View {
    let history: [MetricSnapshot]

    private var chartData: [MetricDataPoint] {
        history.flatMap { snap in [
            MetricDataPoint(turn: snap.turn, metric: "Approval", value: snap.approval),
            MetricDataPoint(turn: snap.turn, metric: "Legitimacy", value: snap.legitimacy),
            MetricDataPoint(turn: snap.turn, metric: "Trust", value: snap.trust),
            MetricDataPoint(turn: snap.turn, metric: "Popularity", value: snap.popularity),
        ]}
    }

    var body: some View {
        Chart(chartData) { dp in
            LineMark(
                x: .value("Turn", dp.turn),
                y: .value("Value", dp.value),
                series: .value("Metric", dp.metric)
            )
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100])
        }
        .chartForegroundStyleScale([
            "Approval": Color.orange,
            "Legitimacy": Color.purple,
            "Trust": Color.blue,
            "Popularity": Color.green,
        ])
        .chartLegend(position: .bottom)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Metric trend chart showing approval, legitimacy, trust, and popularity over \(history.count) turns")
    }
}

#Preview {
    BestEffortsHomeView()
}
