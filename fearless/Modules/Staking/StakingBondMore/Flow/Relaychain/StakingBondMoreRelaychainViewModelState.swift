import Foundation
import BigInt

final class StakingBondMoreRelaychainViewModelState {
    var stateListener: StakingBondMoreModelStateListener?
    let callFactory: SubstrateCallFactoryProtocol = SubstrateCallFactory()
    let chainAsset: ChainAsset
    let dataValidatingFactory: StakingDataValidatingFactoryProtocol
    var amount: Decimal = 0
    var fee: Decimal?
    var balance: Decimal?
    private var stashItem: StashItem?
    private var stashAccount: ChainAccountResponse?

    init(chainAsset: ChainAsset, dataValidatingFactory: StakingDataValidatingFactoryProtocol) {
        self.chainAsset = chainAsset
        self.dataValidatingFactory = dataValidatingFactory
    }
}

extension StakingBondMoreRelaychainViewModelState: StakingBondMoreViewModelState {
    func validators(using locale: Locale) -> [DataValidating] {
        [
            dataValidatingFactory.has(fee: fee, locale: locale, onError: { [unowned self] in
                self.stateListener?.feeParametersDidChanged(viewModelState: self)
            }),

            dataValidatingFactory.canPayFeeAndAmount(
                balance: balance,
                fee: fee,
                spendingAmount: amount,
                locale: locale
            ),

            dataValidatingFactory.has(
                stash: stashAccount,
                for: stashItem?.stash ?? "",
                locale: locale
            )
        ]
    }

    func updateAmount(_ newValue: Decimal) {
        amount = newValue

        stateListener?.provideAsset()
        stateListener?.feeParametersDidChanged(viewModelState: self)
    }

    func selectAmountPercentage(_ percentage: Float) {
        if let balance = balance, let fee = fee {
            let newAmount = max(balance - fee, 0.0) * Decimal(Double(percentage))

            if newAmount > 0 {
                amount = newAmount

                stateListener?.provideAmountInputViewModel()
                stateListener?.provideAsset()
            } else {
                stateListener?.didReceiveInsufficientlyFundsError()
            }
        }
    }

    var feeReuseIdentifier: String? {
        guard let amount = StakingConstants.maxAmount.toSubstrateAmount(
            precision: Int16(chainAsset.asset.precision)
        ) else {
            return nil
        }

        let bondExtra = callFactory.bondExtra(amount: amount)

        return bondExtra.callName
    }

    func setStateListener(_ stateListener: StakingBondMoreModelStateListener?) {
        self.stateListener = stateListener
    }

    var builderClosure: ExtrinsicBuilderClosure? {
        guard let amount = StakingConstants.maxAmount.toSubstrateAmount(
            precision: Int16(chainAsset.asset.precision)
        ) else {
            return nil
        }

        let bondExtra = callFactory.bondExtra(amount: amount)

        return { builder in
            try builder.adding(call: bondExtra)
        }
    }

    var bondMoreConfirmationFlow: StakingBondMoreConfirmationFlow? {
        .relaychain(amount: amount)
    }
}

extension StakingBondMoreRelaychainViewModelState: StakingBondMoreRelaychainStrategyOutput {
    func didReceiveStash(result: Result<ChainAccountResponse?, Error>) {
        switch result {
        case let .success(stashAccount):
            self.stashAccount = stashAccount
        case let .failure(error):
            stateListener?.didReceiveError(error: error)
        }
    }

    func didReceiveStashItem(result: Result<StashItem?, Error>) {
        switch result {
        case let .success(stashItem):
            self.stashItem = stashItem
        case let .failure(error):
            stateListener?.didReceiveError(error: error)
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

            stateListener?.provideAsset()
        case let .failure(error):
            stateListener?.didReceiveError(error: error)
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

            stateListener?.provideFee()
        case let .failure(error):
            stateListener?.didReceiveError(error: error)
        }
    }

    func extrinsicServiceUpdated() {
        stateListener?.feeParametersDidChanged(viewModelState: self)
    }
}
