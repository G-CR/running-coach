import SwiftUI

@main
struct AIRunningCoachApp: App {
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            AuthorizationStatusView(status: container.authorizationStatusModel)
        }
    }
}
