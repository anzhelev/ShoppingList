import UIKit

final class OnboardingViewModel {

    // MARK: - Public Properties
    let descriptions: [String] = [
        .onboardingPage1Description,
        .onboardingPage2Description,
        .onboardingPage3Description
    ]

    let headers: [String] = [
        .onboardingPage1Header,
        .onboardingPage2Header,
        .onboardingPage3Header
    ]

    let images: [String] = [
        "onboardingPage1Image",
        "onboardingPage2Image",
        "onboardingPage3Image"
    ]

    // MARK: - Private Properties
    private let coordinator: Coordinator

    // MARK: - Initializers
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Public Methods
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
        coordinator.showWelcomeScreen()
    }
}
