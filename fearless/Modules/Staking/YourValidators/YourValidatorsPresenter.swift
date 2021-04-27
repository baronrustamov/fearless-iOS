import Foundation

final class YourValidatorsPresenter {
    weak var view: YourValidatorsViewProtocol?
    let wireframe: YourValidatorsWireframeProtocol
    let interactor: YourValidatorsInteractorInputProtocol

    init(interactor: YourValidatorsInteractorInputProtocol, wireframe: YourValidatorsWireframeProtocol) {
        self.interactor = interactor
        self.wireframe = wireframe
    }
}

extension YourValidatorsPresenter: YourValidatorsPresenterProtocol {
    func setup() {
        interactor.setup()
    }
}

extension YourValidatorsPresenter: YourValidatorsInteractorOutputProtocol {
    func didReceiveValidators(result: Result<YourValidatorsModel?, Error>) {
        Logger.shared.info("Validators: \(result)")
    }

    func didReceiveController(result _: Result<AccountItem?, Error>) {}

    func didReceiveElectionStatus(result _: Result<ElectionStatus, Error>) {}
}
