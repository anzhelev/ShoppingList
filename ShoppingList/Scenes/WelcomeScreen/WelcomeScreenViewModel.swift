import Foundation

protocol WelcomeScreenViewModelProtocol {
    var image: String { get }
    var header: String { get }
    var description: String { get }
    func buttonPressed()
}

final class WelcomeScreenViewModel: WelcomeScreenViewModelProtocol {
    
    // MARK: - Public Properties
    let image: String = "launchScreenImage"
    let header: String = .welcomeScreenHeader
    let description: String = .welcomeScreenDescription
    
    // MARK: - Private Properties
    private var coordinator: Coordinator
    
    // MARK: - Initializers
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    // MARK: - Public Methods
    func buttonPressed() {
        coordinator.switchToNewListCreationView()
    }
}
