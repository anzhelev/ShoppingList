import UIKit

final class OnboardingViewModel {
    
    // MARK: - Public Properties
    private var coordinator: Coordinator
   
    let images: [String] = [
        "onboardingPage1Image",
        "onboardingPage2Image",
        "onboardingPage3Image"
    ]
    
    let headers: [String] = [
        .onboardingPage1Header,
        .onboardingPage2Header,
        .onboardingPage3Header
    ]
    
    let descriptions: [String] = [
        .onboardingPage1Description,
        .onboardingPage2Description,
        .onboardingPage3Description
    ]
    
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    func completeOnboarding() {
        coordinator.showWelcomeScreen()
    }
}
