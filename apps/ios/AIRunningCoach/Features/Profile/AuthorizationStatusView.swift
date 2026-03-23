import SwiftUI

struct AuthorizationStatusModel: Equatable {
    let title: String
    let detail: String
    let isAuthorized: Bool
}

struct AuthorizationStatusView: View {
    let status: AuthorizationStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(status.title)
                .font(.headline)
            Text(status.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label(
                status.isAuthorized ? "已就绪" : "待授权",
                systemImage: status.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle"
            )
            .foregroundStyle(status.isAuthorized ? .green : .orange)
        }
        .padding()
    }
}
