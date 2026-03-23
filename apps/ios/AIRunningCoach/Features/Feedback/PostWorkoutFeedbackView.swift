import SwiftUI

struct PostWorkoutFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: PostWorkoutFeedbackViewModel

    @State private var rpe = 7.0
    @State private var fatigue = 4.0
    @State private var soreness = 2.0
    @State private var selectedTags: Set<String> = ["偏吃力", "腿沉"]
    @State private var note = "前半程轻松，后半程腿有点重。"

    private let availableTags = ["偏轻松", "合适", "偏吃力", "腿沉"]

    var body: some View {
        Form {
            Section("强度感受") {
                Slider(value: $rpe, in: 1...10, step: 1)
                Text("RPE \(Int(rpe))")
            }

            Section("身体感受") {
                Slider(value: $fatigue, in: 1...5, step: 1)
                Text("疲劳 \(Int(fatigue))")
                Slider(value: $soreness, in: 1...5, step: 1)
                Text("酸痛 \(Int(soreness))")
            }

            Section("快捷标签") {
                ForEach(availableTags, id: \.self) { tag in
                    Button(tag) {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                }
            }

            Section("自由输入") {
                TextField("训练感受", text: $note, axis: .vertical)
            }

        }
        .navigationTitle("训练反馈")
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            Button("提交反馈") {
                Task {
                    await viewModel.submit(
                        FeedbackDraft(
                            rpe: Int(rpe),
                            fatigue: Int(fatigue),
                            soreness: Int(soreness),
                            selectedTags: Array(selectedTags).sorted(),
                            note: note
                        )
                    )
                    dismiss()
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.top, 8)
            .background(.ultraThinMaterial)
            .accessibilityIdentifier("feedback.submit")
        }
    }
}
