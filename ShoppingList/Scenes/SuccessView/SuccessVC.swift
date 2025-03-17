import UIKit

class SuccessVC: UIViewController {
    
    private let popupView: SuccessView
    
    init(viewModel: SuccessViewModel) {
        self.popupView = SuccessView(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(popupView)
        
        NSLayoutConstraint.activate([
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            popupView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        ])
    }
}
