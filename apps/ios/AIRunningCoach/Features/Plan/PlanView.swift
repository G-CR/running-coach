import SwiftUI

struct PlanView: View {
    @StateObject var viewModel: PlanViewModel

    var body: some View {
        List(viewModel.items) { item in
            VStack(alignment: .leading, spacing: 8) {
                Text("\(item.dateText) · \(item.workoutType)")
                    .font(.headline)
                Text("\(item.durationText) · \(item.intensityText)")
                if item.changed, let changeReason = item.changeReason {
                    Text(changeReason)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(viewModel.windowTitle.isEmpty ? "计划" : viewModel.windowTitle)
        .task {
            await viewModel.load()
        }
    }
}
