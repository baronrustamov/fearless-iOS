import SoraFoundation

protocol YourValidatorListViewProtocol: ControllerBackedProtocol, Localizable, LoadableViewProtocol {
    func reload(state: YourValidatorListViewState)
}

protocol YourValidatorListPresenterProtocol: AnyObject {
    func setup()
    func retry()
    func didSelectValidator(viewModel: YourValidatorViewModel)
    func changeValidators()
}

protocol YourValidatorListInteractorInputProtocol: AnyObject {
    func setup()
    func refresh()
}

protocol YourValidatorListInteractorOutputProtocol: AnyObject {
    func didReceiveValidators(result: Result<YourValidatorsModel?, Error>)
    func didReceiveStashItem(result: Result<StashItem?, Error>)
    func didReceiveLedger(result: Result<StakingLedger?, Error>)
    func didReceiveRewardDestination(result: Result<RewardDestinationArg?, Error>)
    func didReceiveController(result: Result<ChainAccountResponse?, Error>)
}

protocol YourValidatorListWireframeProtocol: AlertPresentable, ErrorPresentable,
    StakingErrorPresentable {
    func present(
        _ validatorInfo: ValidatorInfoProtocol,
        asset: AssetModel,
        chain: ChainModel,
        from view: YourValidatorListViewProtocol?
    )

    func proceedToSelectValidatorsStart(
        from view: YourValidatorListViewProtocol?,
        asset: AssetModel,
        chain: ChainModel,
        selectedAccount: MetaAccountModel,
        existingBonding: ExistingBonding
    )
}
