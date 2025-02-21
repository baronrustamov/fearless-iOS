import Foundation
import SoraFoundation

final class AllDonePresenter {
    // MARK: Private properties

    private weak var view: AllDoneViewInput?
    private let router: AllDoneRouterInput
    private let interactor: AllDoneInteractorInput

    private let hashString: String

    // MARK: - Constructors

    init(
        hashString: String,
        interactor: AllDoneInteractorInput,
        router: AllDoneRouterInput,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.hashString = hashString
        self.interactor = interactor
        self.router = router
        self.localizationManager = localizationManager
    }

    // MARK: - Private methods

    private func provideHashString() {
        view?.didReceive(hashString: hashString)
    }
}

// MARK: - AllDoneViewOutput

extension AllDonePresenter: AllDoneViewOutput {
    func didLoad(view: AllDoneViewInput) {
        self.view = view
        interactor.setup(with: self)
        provideHashString()
    }
}

// MARK: - AllDoneInteractorOutput

extension AllDonePresenter: AllDoneInteractorOutput {
    func dismiss() {
        router.dismiss(view: view)
    }

    func didCopyTapped() {
        let copyEvent = HashCopiedEvent(locale: selectedLocale)
        router.presentStatus(with: copyEvent, animated: true)
    }
}

// MARK: - Localizable

extension AllDonePresenter: Localizable {
    func applyLocalization() {
        provideHashString()
    }
}

extension AllDonePresenter: AllDoneModuleInput {}
