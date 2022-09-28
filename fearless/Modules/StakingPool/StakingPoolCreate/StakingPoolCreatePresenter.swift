import Foundation
import SoraFoundation
import BigInt

struct StakingPoolCreateData {
    let poolId: UInt32
    let poolName: String
    let amount: Decimal
    let root: MetaAccountModel
    let nominator: MetaAccountModel
    let stateToggler: MetaAccountModel
    let chainAsset: ChainAsset
}

final class StakingPoolCreatePresenter {
    // MARK: Private properties

    private weak var view: StakingPoolCreateViewInput?
    private let router: StakingPoolCreateRouterInput
    private let interactor: StakingPoolCreateInteractorInput

    private let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    private let viewModelFactory: StakingPoolCreateViewModelFactoryProtocol
    private let dataValidatingFactory: StakingDataValidatingFactoryProtocol
    private let logger: LoggerProtocol
    private let wallet: MetaAccountModel
    private let chainAsset: ChainAsset

    private var inputResult: AmountInputResult?
    private var priceData: PriceData?
    private var balance: Decimal?
    private var fee: Decimal?
    private var balanceMinusFee: Decimal { (balance ?? 0) - (fee ?? 0) }
    private var minCreateBond: Decimal?
    private var nominatorWallet: MetaAccountModel
    private var stateTogglerWallet: MetaAccountModel
    private var lastPoolId: UInt32?
    private var poolNameInputViewModel: InputViewModelProtocol

    // MARK: - Constructors

    init(
        interactor: StakingPoolCreateInteractorInput,
        router: StakingPoolCreateRouterInput,
        localizationManager: LocalizationManagerProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        viewModelFactory: StakingPoolCreateViewModelFactoryProtocol,
        dataValidatingFactory: StakingDataValidatingFactoryProtocol,
        logger: LoggerProtocol,
        wallet: MetaAccountModel,
        chainAsset: ChainAsset,
        amount: Decimal?
    ) {
        self.interactor = interactor
        self.router = router
        self.balanceViewModelFactory = balanceViewModelFactory
        self.viewModelFactory = viewModelFactory
        self.dataValidatingFactory = dataValidatingFactory
        self.logger = logger
        self.wallet = wallet
        self.chainAsset = chainAsset
        nominatorWallet = wallet
        stateTogglerWallet = wallet

        let nameInputHandling = InputHandler(predicate: NSPredicate.notEmpty)
        poolNameInputViewModel = InputViewModel(inputHandler: nameInputHandling)

        if let amount = amount {
            inputResult = .absolute(amount)
        }

        self.localizationManager = localizationManager
    }

    // MARK: - Private methods

    private func provideViewModel() {
        let viewModel = viewModelFactory.buildViewModel(
            wallet: wallet,
            nominatorWallet: nominatorWallet,
            stateToggler: stateTogglerWallet,
            lastPoolId: lastPoolId
        )
        view?.didReceiveViewModel(viewModel)
    }

    private func provideAssetVewModel() {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee) ?? 0.0

        let assetBalanceViewModel = balanceViewModelFactory.createAssetBalanceViewModel(
            inputAmount,
            balance: balance,
            priceData: priceData
        ).value(for: selectedLocale)

        view?.didReceiveAssetBalanceViewModel(assetBalanceViewModel)
    }

    private func provideFeeViewModel() {
        guard let fee = fee else {
            view?.didReceiveFeeViewModel(nil)
            return
        }

        let feeViewModel = balanceViewModelFactory.balanceFromPrice(fee, priceData: priceData)
        view?.didReceiveFeeViewModel(feeViewModel.value(for: selectedLocale))
    }

    private func provideInputViewModel() {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee)

        let inputViewModel = balanceViewModelFactory.createBalanceInputViewModel(inputAmount)
            .value(for: selectedLocale)

        view?.didReceiveAmountInputViewModel(inputViewModel)
    }

    private func presentAlert() {
        let languages = localizationManager?.selectedLocale.rLanguages

        let action = AlertPresentableAction(
            title: R.string.localizable.commonCancelOperationAction(preferredLanguages: languages),
            style: .destructive
        ) { [weak self] in
            self?.router.dismiss(view: self?.view)
        }

        let viewModel = AlertPresentableViewModel(
            title: R.string.localizable.stakingPoolCreateMissingNameTitle(preferredLanguages: languages),
            message: nil,
            actions: [action],
            closeAction: nil
        )

        router.present(viewModel: viewModel, style: .alert, from: view)
    }
}

// MARK: - StakingPoolCreateViewOutput

extension StakingPoolCreatePresenter: StakingPoolCreateViewOutput {
    func createDidTapped() {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee) ?? 0.0
        DataValidationRunner(validators: [
            dataValidatingFactory.canNominate(
                amount: inputAmount,
                minimalBalance: minCreateBond,
                minNominatorBond: minCreateBond,
                locale: selectedLocale
            ),
            dataValidatingFactory.has(
                fee: fee,
                locale: selectedLocale,
                onError: { [weak self] in
                    self?.interactor.estimateFee()
                }
            ),
            dataValidatingFactory.canPayFeeAndAmount(
                balance: balance,
                fee: fee,
                spendingAmount: inputAmount,
                locale: selectedLocale
            ),
            dataValidatingFactory.createPoolName(
                complite: poolNameInputViewModel.inputHandler.completed,
                locale: selectedLocale
            )
        ]).runValidation { [weak self] in
            guard
                let strongSelf = self,
                let lastPoolId = strongSelf.lastPoolId
            else {
                return
            }

            let createData = StakingPoolCreateData(
                poolId: lastPoolId + 1,
                poolName: strongSelf.poolNameInputViewModel.inputHandler.value,
                amount: inputAmount,
                root: strongSelf.wallet,
                nominator: strongSelf.nominatorWallet,
                stateToggler: strongSelf.stateTogglerWallet,
                chainAsset: strongSelf.chainAsset
            )

            strongSelf.router.showConfirm(from: strongSelf.view, with: createData)
        }
    }

    func nominatorDidTapped() {
        router.showWalletManagment(
            contextTag: StakingPoolCreateContextTag.nominator.rawValue,
            from: view,
            moduleOutput: self
        )
    }

    func stateTogglerDidTapped() {
        router.showWalletManagment(
            contextTag: StakingPoolCreateContextTag.stateToggler.rawValue,
            from: view,
            moduleOutput: self
        )
    }

    func selectAmountPercentage(_ percentage: Float) {
        inputResult = .rate(Decimal(Double(percentage)))
    }

    func updateAmount(_ newValue: Decimal) {
        inputResult = .absolute(newValue)
    }

    func didLoad(view: StakingPoolCreateViewInput) {
        self.view = view
        interactor.setup(with: self)
        interactor.estimateFee()
        provideViewModel()

        view.didReceive(nameViewModel: poolNameInputViewModel)
    }

    func backDidTapped() {
        router.dismiss(view: view)
    }
}

// MARK: - StakingPoolCreateInteractorOutput

extension StakingPoolCreatePresenter: StakingPoolCreateInteractorOutput {
    func didReceiveLastPoolId(_ lastPoolId: UInt32?) {
        self.lastPoolId = lastPoolId
        provideViewModel()
    }

    func didReceivePoolMember(_ poolMember: StakingPoolMember?) {
        if poolMember != nil {
            presentAlert()
        }
    }

    func didReceiveMinBond(_ minCreateBond: BigUInt?) {
        guard let minCreateBond = minCreateBond else {
            return
        }

        self.minCreateBond = Decimal.fromSubstrateAmount(
            minCreateBond,
            precision: Int16(chainAsset.asset.precision)
        )
    }

    func didReceivePriceData(result: Result<PriceData?, Error>) {
        switch result {
        case let .success(priceData):
            self.priceData = priceData

            provideAssetVewModel()
            provideInputViewModel()
            provideFeeViewModel()
        case let .failure(error):
            logger.error("error: \(error)")
        }
    }

    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>) {
        switch result {
        case let .success(accountInfo):
            if let accountInfo = accountInfo {
                balance = Decimal.fromSubstrateAmount(
                    accountInfo.data.available,
                    precision: Int16(chainAsset.asset.precision)
                )
            } else {
                balance = nil
            }

            provideAssetVewModel()
        case let .failure(error):
            logger.error("error: \(error)")
        }
    }

    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>) {
        switch result {
        case let .success(dispatchInfo):
            if let feeValue = BigUInt(dispatchInfo.fee) {
                fee = Decimal.fromSubstrateAmount(feeValue, precision: Int16(chainAsset.asset.precision))
            } else {
                fee = nil
            }

            provideAssetVewModel()
            provideFeeViewModel()
        case let .failure(error):
            logger.error("error: \(error)")
        }
    }
}

// MARK: - Localizable

extension StakingPoolCreatePresenter: Localizable {
    func applyLocalization() {
        provideAssetVewModel()
        provideInputViewModel()
        provideFeeViewModel()
    }
}

extension StakingPoolCreatePresenter: StakingPoolCreateModuleInput {}

extension StakingPoolCreatePresenter: WalletsManagmentModuleOutput {
    private enum StakingPoolCreateContextTag: Int {
        case nominator = 0
        case stateToggler
    }

    func selectedWallet(_ wallet: MetaAccountModel, for contextTag: Int) {
        guard let contextTag = StakingPoolCreateContextTag(rawValue: contextTag) else {
            return
        }

        switch contextTag {
        case .nominator:
            nominatorWallet = wallet
        case .stateToggler:
            stateTogglerWallet = wallet
        }

        provideViewModel()
    }
}
