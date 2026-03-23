import SwiftUI

struct AIRunningCoachRootView: View {
    enum Tab: Hashable {
        case home
        case workouts
        case plan
        case profile
    }

    let container: AppContainer
    @State private var selectedTab: Tab = .home
    @State private var homeReloadToken = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    viewModel: HomeViewModel(service: container.homeService),
                    openWorkouts: { selectedTab = .workouts },
                    openPlan: { selectedTab = .plan },
                    reloadToken: homeReloadToken
                )
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(Tab.home)

            NavigationStack {
                WorkoutListView(service: container.workoutService)
            }
            .tabItem {
                Label("训练", systemImage: "figure.run")
            }
            .tag(Tab.workouts)

            NavigationStack {
                PlanView(viewModel: PlanViewModel(service: container.planService))
            }
            .tabItem {
                Label("计划", systemImage: "calendar")
            }
            .tag(Tab.plan)

            NavigationStack {
                GoalSettingsView(
                    viewModel: GoalSettingsViewModel(
                        goalService: container.goalService,
                        authorizationService: container.authorizationService,
                        workoutReader: container.workoutReader,
                        syncCoordinator: container.syncCoordinator,
                        userID: container.localUserID
                    )
                )
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
            .tag(Tab.profile)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .home {
                homeReloadToken += 1
            }
        }
    }
}
