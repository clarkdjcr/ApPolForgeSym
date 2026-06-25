import SwiftUI
import Combine
import BestEffortsCore

@MainActor
final class BestEffortsViewModel: ObservableObject {
    @Published var config = SimulationConfig()
    @Published var seedText: String = "0"

    @Published private(set) var result: SimulationResult?
    @Published private(set) var history: [MetricSnapshot] = []
    @Published private(set) var isRunning = false

    var isFinished: Bool { result != nil }

    var seed: UInt64 { UInt64(seedText) ?? 0 }

    var outcomeText: String {
        guard let r = result else { return "" }
        switch r.outcome {
        case .fourthEstateWins(let term, let realignments):
            return "Fourth Estate wins — Term \(term), \(realignments) realignment\(realignments == 1 ? "" : "s")"
        case .statusQuoPrevails(let term):
            return "Status quo prevails — \(term) terms elapsed"
        case .ongoing:
            return "In progress"
        }
    }

    var outcomeIsFourthEstateWin: Bool {
        if case .fourthEstateWins = result?.outcome { return true }
        return false
    }

    func run() {
        isRunning = true
        let sim = Simulation(config: config, seed: seed)
        result = sim.run()
        history = sim.history
        isRunning = false
    }

    func reset() {
        result = nil
        history = []
    }

    func randomizeSeed() {
        seedText = String(UInt64.random(in: 0...UInt64.max))
    }
}
