import UIKit

final class OnboardingViewController: UIPageViewController {

    // MARK: - Private Properties
    private let viewModel: OnboardingViewModel

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)
        button.backgroundColor = .buttonBgrTertiary
        button.layer.cornerRadius = 10
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.titleLabel?.font = .listScreenTitle
        return button
    }()

    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        pageControl.backgroundStyle = .prominent
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .textColorPrimary
        pageControl.numberOfPages = pages.count
        pageControl.pageIndicatorTintColor = .textColorPrimary.withAlphaComponent(0.3)
        return pageControl
    }()

    private lazy var pages: [UIViewController] = {
        zip(zip(viewModel.images, viewModel.headers), viewModel.descriptions).map { value in
            let ((image, header), description) = value
            return generatePage(with: image, header: header, description: description)
        }
    }()

    // MARK: - Initializers
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        view.backgroundColor = .screenBgrPrimary

        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: false)
        }
        setupControls()
        updateContinueButton()
    }

    // MARK: - Private Methods
    private func generatePage(with image: String, header: String, description: String) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .screenBgrPrimary

        let imageView = UIImageView(image: UIImage(named: image))
        imageView.contentMode = .scaleAspectFit
        let stackView = UIStackView(
            arrangedSubviews: [
                imageView,
                makeLabel(text: header, font: .mainScreenTitle, numberOfLines: 2),
                makeLabel(text: description, font: .itemName, numberOfLines: 0)
            ]
        )
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor, constant: -30),
            stackView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 25),
            stackView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -25),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: viewController.view.heightAnchor, multiplier: 0.45),
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
        return viewController
    }

    private func makeLabel(text: String, font: UIFont, numberOfLines: Int) -> UILabel {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = font
        label.numberOfLines = numberOfLines
        label.text = text
        label.textAlignment = .center
        label.textColor = .textColorPrimary
        return label
    }

    private func setupControls() {
        [pageControl, continueButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func updateContinueButton() {
        let title: String = pageControl.currentPage == pages.count - 1 ? .onboardingStart : .onboardingContinue
        continueButton.setTitle(title, for: .normal)
    }

    // MARK: - Actions
    @objc private func continueButtonPressed() {
        let nextIndex = pageControl.currentPage + 1
        guard nextIndex < pages.count else {
            viewModel.completeOnboarding()
            return
        }

        setViewControllers([pages[nextIndex]], direction: .forward, animated: true)
        pageControl.currentPage = nextIndex
        updateContinueButton()
    }

    @objc private func pageControlChanged() {
        guard let currentPage = viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentPage),
              pages.indices.contains(pageControl.currentPage) else {
            return
        }

        let direction: UIPageViewController.NavigationDirection = pageControl.currentPage > currentIndex
            ? .forward
            : .reverse
        setViewControllers([pages[pageControl.currentPage]], direction: direction, animated: true)
        updateContinueButton()
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), pages.indices.contains(index + 1) else {
            return nil
        }
        return pages[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), pages.indices.contains(index - 1) else {
            return nil
        }
        return pages[index - 1]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentPage = pageViewController.viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentPage) else {
            return
        }

        pageControl.currentPage = currentIndex
        updateContinueButton()
    }
}
