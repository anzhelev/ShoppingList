import Foundation

extension String {

    // MARK: - Public Properties
    static var dateFormat: String { localized("formatter.dateFormat") }

    static var appName: String { localized("app.name") }

    static var notificationText: String { localized("notification.text") }

    static var buttonAddProduct: String { localized("buttons.addProduct") }
    static var buttonApply: String { localized("buttons.apply") }
    static var buttonBack: String { localized("buttons.back") }
    static var buttonCancel: String { localized("buttons.cancel") }
    static var buttonClear: String { localized("buttons.clear") }
    static var buttonClearArchive: String { localized("buttons.clearArchive") }
    static var buttonCreateNewList: String { localized("buttons.createNewList") }
    static var buttonDelete: String { localized("buttons.delete") }
    static var buttonDone: String { localized("buttons.done") }
    static var buttonEdit: String { localized("buttons.edit") }
    static var buttonOk: String { localized("buttons.ok") }
    static var buttonPin: String { localized("buttons.pin") }
    static var buttonRemoveCheckedItems: String { localized("buttons.removeCheckedItems") }
    static var buttonRestore: String { localized("buttons.restore") }
    static var buttonRestoreList: String { localized("buttons.restoreList") }
    static var buttonSaveList: String { localized("buttons.saveList") }
    static var buttonSettings: String { localized("buttons.settings") }
    static var buttonSwitchToMainScreen: String { localized("buttons.switchToMainScreen") }
    static var buttonUnpin: String { localized("buttons.unpin") }

    static var dropdownDuplicate: String { localized("dropdown.duplicate") }
    static var dropdownRemind: String { localized("dropdown.remind") }
    static var dropdownReset: String { localized("dropdown.reset") }
    static var dropdownShare: String { localized("dropdown.share") }
    static var dropdownSorting: String { localized("dropdown.sorting") }

    static var languageEnglish: String { localized("languages.english") }
    static var languageRussian: String { localized("languages.russian") }
    static var languageSystem: String { localized("languages.system") }

    static var themeAutomatic: String { localized("themes.automatic") }
    static var themeDark: String { localized("themes.dark") }
    static var themeLight: String { localized("themes.light") }
    
    static var splashScreenLogoImage: String { localized("splashScreen.logo.imageName") }

    static var onboardingContinue: String { localized("onboarding.continue") }
    static var onboardingPage1Description: String { localized("onboarding.page1.description") }
    static var onboardingPage1Header: String { localized("onboarding.page1.header") }
    static var onboardingPage2Description: String { localized("onboarding.page2.description") }
    static var onboardingPage2Header: String { localized("onboarding.page2.header") }
    static var onboardingPage3Description: String { localized("onboarding.page3.description") }
    static var onboardingPage3Header: String { localized("onboarding.page3.header") }
    static var onboardingStart: String { localized("onboarding.start") }

    static var welcomeScreenHeader: String { localized("welcomeScreen.header") }

    static var tabBarTabsArchiveView: String { localized("tabBar.archiveView") }
    static var tabBarTabsMainView: String { localized("tabBar.mainView") }
    static var tabBarTabsSettingsView: String { localized("tabBar.settingsView") }

    static var mainScreenActiveSwipeHint: String { localized("mainScreenViewController.active.swipeHint") }
    static var mainScreenActiveTitle: String { localized("mainScreenViewController.active.title") }
    static var mainScreenCompletedSwipeHint: String { localized("mainScreenViewController.completed.swipeHint") }
    static var mainScreenCompletedTitle: String { localized("mainScreenViewController.completed.title") }
    static var mainScreenStub: String { localized("mainScreenViewController.stub") }

    static var newListAddProductHint: String { localized("newListViewController.addProductHint") }
    static var newListCreationTitle: String { localized("newListViewController.title") }
    static var newListEmptyName: String { localized("newListViewController.emptyName") }
    static var newListItemPlaceholder: String { localized("newListViewController.itemPlaceholder") }
    static var newListNameAlreadyUsed: String { localized("newListViewController.nameAlreadyUsed") }
    static var newListTitlePlaceholder: String { localized("newListViewController.titlePlaceholder") }
    static var newListWrongName: String { localized("newListViewController.wrongName") }

    static var shoppingListVCcheckAll: String { localized("shoppingListViewController.checkAll") }
    static var successViewAdditional: String { localized("successView.additional") }
    static var successViewCongratulations: String { localized("successView.congratulations") }

    static var datePickerViewTitle: String { localized("datePickerView.title") }

    static var errorTitle: String { localized("errors.title") }
    static var listDuplicatedMessage: String { localized("shoppingList.duplicatedMessage") }
    static var notificationInvalidDate: String { localized("notifications.invalidDate") }
    static var notificationPermissionDenied: String { localized("notifications.permissionDenied") }
    static var notificationSchedulingFailed: String { localized("notifications.schedulingFailed") }
    static var notificationScheduledMessage: String { localized("notifications.scheduledMessage") }
    static var notificationScheduledTitle: String { localized("notifications.scheduledTitle") }
    static var storageListAlreadyExists: String { localized("storage.listAlreadyExists") }
    static var storageListNotFound: String { localized("storage.listNotFound") }

    static var settingsAlertMessage: String { localized("settings.alert.message") }
    static var settingsAlertTitle: String { localized("settings.alert.title") }
    static var settingsLanguageSectionTitle: String { localized("settings.languageSettings.title") }
    static var settingsThemeSectionTitle: String { localized("settings.themeSettings.title") }

    // MARK: - Private Methods
    private static func localized(_ key: String) -> String {
        LanguageManager.languageManager.localizedString(forKey: key)
    }
}
