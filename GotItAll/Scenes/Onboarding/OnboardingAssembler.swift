import UIKit

final class OnboardingAssembler {

    // MARK: - Public Methods
    public func build(coordinator: Coordinator) -> UIPageViewController {
        let viewModel = OnboardingViewModel(coordinator: coordinator)
        return OnboardingViewController(viewModel: viewModel)
    }
}
