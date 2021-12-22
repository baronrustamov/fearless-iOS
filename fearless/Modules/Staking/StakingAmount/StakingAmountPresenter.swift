import Foundation
import CommonWallet
import BigInt

final class StakingAmountPresenter {
    weak var view: StakingAmountViewProtocol?
    var wireframe: StakingAmountWireframeProtocol!
    var interactor: StakingAmountInteractorInputProtocol!

    let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    let rewardDestViewModelFactory: RewardDestinationViewModelFactoryProtocol
    let selectedAccount: MetaAccountModel
    let logger: LoggerProtocol
    let applicationConfig: ApplicationConfigProtocol
    let dataValidatingFactory: StakingDataValidatingFactoryProtocol

    private var calculator: RewardCalculatorEngineProtocol?
    private var priceData: PriceData?
    private var balance: Decimal?
    private var fee: Decimal?
    private var loadingFee: Bool = false
    private var asset: AssetModel
    private var chain: ChainModel
    private var amount: Decimal?
    private var rewardDestination: RewardDestination<ChainAccountResponse> = .restake
    private var payoutAccount: ChainAccountResponse?
    private var loadingPayouts: Bool = false
    private var minimalBalance: Decimal?
    private var minBondAmount: Decimal?
    private var counterForNominators: UInt32?
    private var maxNominatorsCount: UInt32?

    init(
        amount: Decimal?,
        asset: AssetModel,
        chain: ChainModel,
        selectedAccount: MetaAccountModel,
        rewardDestViewModelFactory: RewardDestinationViewModelFactoryProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        dataValidatingFactory: StakingDataValidatingFactoryProtocol,
        applicationConfig: ApplicationConfigProtocol,
        logger: LoggerProtocol
    ) {
        self.amount = amount
        self.asset = asset
        self.chain = chain
        self.selectedAccount = selectedAccount
        payoutAccount = selectedAccount.fetch(for: chain.accountRequest())
        self.rewardDestViewModelFactory = rewardDestViewModelFactory
        self.balanceViewModelFactory = balanceViewModelFactory
        self.dataValidatingFactory = dataValidatingFactory
        self.applicationConfig = applicationConfig
        self.logger = logger
    }

    private func provideRewardDestination() {
        do {
            let reward: CalculatedReward?

            if let calculator = calculator {
                let restake = calculator.calculateMaxReturn(
                    isCompound: true,
                    period: .year
                )

                let payout = calculator.calculateMaxReturn(
                    isCompound: false,
                    period: .year
                )

                let curAmount = amount ?? 0.0
                reward = CalculatedReward(
                    restakeReturn: restake * curAmount,
                    restakeReturnPercentage: restake,
                    payoutReturn: payout * curAmount,
                    payoutReturnPercentage: payout
                )
            } else {
                reward = nil
            }

            switch rewardDestination {
            case .restake:
                let viewModel = rewardDestViewModelFactory.createRestake(from: reward, priceData: priceData)
                view?.didReceiveRewardDestination(viewModel: viewModel)
            case .payout:
                if let payoutAccount = payoutAccount, let address = payoutAccount.toAddress() {
                    let viewModel = try rewardDestViewModelFactory
                        .createPayout(from: reward, priceData: priceData, address: address)
                    view?.didReceiveRewardDestination(viewModel: viewModel)
                }
            }
        } catch {
            logger.error("Can't create reward destination")
        }
    }

    private func provideAsset() {
        let viewModel = balanceViewModelFactory.createAssetBalanceViewModel(
            amount ?? 0.0,
            balance: balance,
            priceData: priceData
        )
        view?.didReceiveAsset(viewModel: viewModel)
    }

    private func provideFee() {
        if let fee = fee {
            let feeViewModel = balanceViewModelFactory.balanceFromPrice(fee, priceData: priceData)
            view?.didReceiveFee(viewModel: feeViewModel)
        } else {
            view?.didReceiveFee(viewModel: nil)
        }
    }

    private func provideAmountInputViewModel() {
        let viewModel = balanceViewModelFactory.createBalanceInputViewModel(amount)
        view?.didReceiveInput(viewModel: viewModel)
    }

    private func scheduleFeeEstimation() {
        if !loadingFee, fee == nil {
            estimateFee()
        }
    }

    private func estimateFee() {
        if let amount = StakingConstants.maxAmount.toSubstrateAmount(precision: Int16(asset.precision)),
           let payoutAccount = payoutAccount,
           let address = selectedAccount.fetch(for: chain.accountRequest())?.toAddress() {
            loadingFee = true
            interactor.estimateFee(
                for: address,
                amount: amount,
                rewardDestination: .payout(account: payoutAccount)
            )
        }
    }
}

extension StakingAmountPresenter: StakingAmountPresenterProtocol {
    func setup() {
        provideAmountInputViewModel()
        provideRewardDestination()

        interactor.setup()

        estimateFee()
    }

    func selectRestakeDestination() {
        rewardDestination = .restake
        provideRewardDestination()

        scheduleFeeEstimation()
    }

    func selectPayoutDestination() {
        guard let payoutAccount = payoutAccount else {
            return
        }

        rewardDestination = .payout(account: payoutAccount)
        provideRewardDestination()

        scheduleFeeEstimation()
    }

    func selectAmountPercentage(_ percentage: Float) {
        if let balance = balance, let fee = fee {
            let newAmount = max(balance - fee, 0.0) * Decimal(Double(percentage))

            if newAmount > 0 {
                amount = newAmount

                provideAmountInputViewModel()
                provideAsset()
                provideRewardDestination()
            } else if let view = view {
                wireframe.presentAmountTooHigh(
                    from: view,
                    locale: view.localizationManager?.selectedLocale
                )
            }
        }
    }

    func selectPayoutAccount() {
        guard !loadingPayouts else {
            return
        }

        loadingPayouts = true

        interactor.fetchAccounts()
    }

    func selectLearnMore() {
        if let view = view {
            wireframe.showWeb(
                url: applicationConfig.learnPayoutURL,
                from: view,
                style: .automatic
            )
        }
    }

    func updateAmount(_ newValue: Decimal) {
        amount = newValue

        provideAsset()
        provideRewardDestination()
        scheduleFeeEstimation()
    }

    func proceed() {
        let locale = view?.localizationManager?.selectedLocale ?? Locale.current

        DataValidationRunner(validators: [
            dataValidatingFactory.has(fee: fee, locale: locale) { [weak self] in
                self?.scheduleFeeEstimation()
            },
            dataValidatingFactory.canPayFeeAndAmount(
                balance: balance,
                fee: fee,
                spendingAmount: amount,
                locale: locale
            ),
            dataValidatingFactory.canNominate(
                amount: amount,
                minimalBalance: minimalBalance,
                minNominatorBond: minBondAmount,
                locale: locale
            ),
            dataValidatingFactory.maxNominatorsCountNotApplied(
                counterForNominators: counterForNominators,
                maxNominatorsCount: maxNominatorsCount,
                hasExistingNomination: false,
                locale: locale
            )
        ]).runValidation { [weak self] in
            guard
                let self = self,
                let amount = self.amount
            else {
                return
            }

            let stakingState = InitiatedBonding(
                amount: amount,
                rewardDestination: self.rewardDestination
            )

            self.wireframe.proceed(
                from: self.view,
                state: stakingState,
                asset: self.asset,
                chain: self.chain,
                selectedAccount: self.selectedAccount
            )
        }
    }

    func close() {
        wireframe.close(view: view)
    }
}

extension StakingAmountPresenter: SchedulerDelegate {
    func didTrigger(scheduler _: SchedulerProtocol) {
        estimateFee()
    }
}

extension StakingAmountPresenter: StakingAmountInteractorOutputProtocol {
    func didReceive(accounts: [ChainAccountResponse]) {
        loadingPayouts = false

        let context = PrimitiveContextWrapper(value: accounts)

        // TODO: Restore logic if needed
//        wireframe.presentAccountSelection(
//            accounts,
//            selectedAccountItem: payoutAccountAddress,
//            delegate: self,
//            from: view,
//            context: context
//        )
    }

    func didReceive(price: PriceData?) {
        priceData = price
        provideAsset()
        provideFee()
        provideRewardDestination()
    }

    func didReceive(balance: AccountData?) {
        if let availableValue = balance?.available {
            self.balance = Decimal.fromSubstrateAmount(
                availableValue,
                precision: Int16(asset.precision)
            )
        } else {
            self.balance = 0.0
        }

        provideAsset()
    }

    func didReceive(
        paymentInfo: RuntimeDispatchInfo,
        for _: BigUInt,
        rewardDestination _: RewardDestination<AccountAddress>
    ) {
        loadingFee = false

        if let feeValue = BigUInt(paymentInfo.fee),
           let fee = Decimal.fromSubstrateAmount(feeValue, precision: Int16(asset.precision)) {
            self.fee = fee
        } else {
            fee = nil
        }

        provideFee()
    }

    func didReceive(error: Error) {
        loadingPayouts = false
        loadingFee = false

        let locale = view?.localizationManager?.selectedLocale

        if !wireframe.present(error: error, from: view, locale: locale) {
            logger.error("Did receive error: \(error)")
        }
    }

    func didReceive(calculator: RewardCalculatorEngineProtocol) {
        self.calculator = calculator
        provideRewardDestination()
    }

    func didReceive(calculatorError: Error) {
        let locale = view?.localizationManager?.selectedLocale
        if !wireframe.present(error: calculatorError, from: view, locale: locale) {
            logger.error("Did receive error: \(calculatorError)")
        }
    }

    func didReceive(minimalBalance: BigUInt) {
        if let amount = Decimal.fromSubstrateAmount(minimalBalance, precision: Int16(asset.precision)) {
            logger.debug("Did receive minimun bonding amount: \(amount)")
            self.minimalBalance = amount
        }
    }

    func didReceive(minBondAmount: BigUInt?) {
        self.minBondAmount = minBondAmount.map { Decimal.fromSubstrateAmount($0, precision: Int16(asset.precision)) } ?? nil
    }

    func didReceive(counterForNominators: UInt32?) {
        self.counterForNominators = counterForNominators
    }

    func didReceive(maxNominatorsCount: UInt32?) {
        self.maxNominatorsCount = maxNominatorsCount
    }
}

extension StakingAmountPresenter: ModalPickerViewControllerDelegate {
    func modalPickerDidSelectModelAtIndex(_ index: Int, context: AnyObject?) {
        guard
            let accounts =
            (context as? PrimitiveContextWrapper<[ChainAccountResponse]>)?.value
        else {
            return
        }

        payoutAccount = accounts[index]

        if let payoutAccount = payoutAccount, case .payout = rewardDestination {
            rewardDestination = .payout(account: payoutAccount)
        }

        provideRewardDestination()
    }
}
