import UIKit

final class OnboardingAssembler {    
    public func build(coordinator: Coordinator) -> UIPageViewController {
        let viewModel = OnboardingViewModel(coordinator: coordinator)
        let viewController = OnboardingViewController()
        viewController.viewModel = viewModel
        return viewController
    }
}
