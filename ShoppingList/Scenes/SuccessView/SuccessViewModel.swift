import UIKit

final class SuccessViewModel {
    
    // MARK: - Public Properties
    var switchToMainView: Observable<Bool> = Observable(nil)
    
    // MARK: - Private Properties
    private let listName: String
    
    //MARK: - Initializers
    init(listName: String) {
        self.listName = listName
    }
    
    // MARK: - Public Methods
    func getListName() -> String {
        listName
    }
    
    // MARK: - Actions
    func buttonTapped() {
        switchToMainView.value = true
    }
}
