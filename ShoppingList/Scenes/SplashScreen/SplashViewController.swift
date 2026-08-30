import UIKit

final class SplashViewController: UIViewController {

    // MARK: - Private Properties
    private let animationImageView = UIImageView(image: UIImage(named: "launchScreenImage"))
    private let logoImageView = UIImageView(image: UIImage(named: "launchScreenLogo"))
    private let transitionView = UIView()
    private let viewModel: SplashViewModel

    // MARK: - Initializers
    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleAnimation()
    }

    // MARK: - Private Methods
    private func setUI() {
        view.backgroundColor = .screenBgrPrimary
        transitionView.backgroundColor = .screenBgrPrimary
        logoImageView.alpha = 0
        transitionView.alpha = 0

        [logoImageView, animationImageView, transitionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            animationImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            transitionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            transitionView.heightAnchor.constraint(equalTo: view.heightAnchor),

            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            logoImageView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150)
        ])
    }

    private func titleAnimation() {
        UIView.animate(
            withDuration: 1.3,
            animations: {
                self.logoImageView.alpha = 1
            },
            completion: { [weak self] _ in
                self?.imageAnimation()
            }
        )
    }

    private func imageAnimation() {
        UIView.animate(
            withDuration: 2,
            delay: 0.3,
            animations: {
                self.animationImageView.transform = CGAffineTransform(scaleX: 1 / 50, y: 1 / 50)
                self.transitionView.alpha = 1
            },
            completion: { [weak self] _ in
                self?.viewModel.animationCompleted()
            }
        )
    }
}
