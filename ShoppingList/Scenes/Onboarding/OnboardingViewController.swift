import UIKit

class OnboardingViewController: UIPageViewController {
    
    // MARK: - Private Properties
    var viewModel: OnboardingViewModel? = nil
    
    private lazy var pages: [UIViewController] = {
        var pages : [UIViewController] = []
        guard let viewModel else {
            return pages
        }
        for pageNumber in 0 ..< 3 {
            pages.append(
                generatePage(
                    with: viewModel.images[pageNumber],
                    header: viewModel.headers[pageNumber],
                    description: viewModel.descriptions[pageNumber]
                )
            )
        }
        return pages
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .black.withAlphaComponent(0.3)
        pageControl.backgroundStyle = .prominent
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
        
        setPageControl()
    }
    
    private func generatePage(with image: String, header: String, description: String) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .screenBgrPrimary
        let stackSubviews: [UIView] = [
            UIImageView(image: UIImage(named: image)),
            setHeaderLabel(with: header),
            setDescriptionLabel(with: description)
        ]
        
        let stackView = setStackView(with: stackSubviews)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(stackView)
        
        stackView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 25).isActive = true
        stackView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -25).isActive = true
        return vc
    }
    
    private func setStackView(with subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 25
        return stackView
    }
    
    private func setHeaderLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = .mainScreenTitle
        label.textColor = .black
        label.numberOfLines = 2
        return label
    }
    
    private func setDescriptionLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = .itemName
        label.textColor = .black
        label.numberOfLines = 3
        return label
    }
    
    private func setPageControl() {
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -45),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}


// MARK: - UIPageViewControllerDataSource
extension OnboardingViewController: UIPageViewControllerDataSource{
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else {
            self.viewModel?.completeOnboarding()
            return nil
        }
        return pages[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
}
