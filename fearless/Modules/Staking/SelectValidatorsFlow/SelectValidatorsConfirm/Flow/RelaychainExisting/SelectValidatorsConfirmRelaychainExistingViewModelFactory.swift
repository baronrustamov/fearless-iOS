import Foundation
import FearlessUtils
import SoraFoundation

final class SelectValidatorsConfirmRelaychainExistingViewModelFactory {
    private let iconGenerator: IconGenerating
    private let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    private lazy var amountFactory: AssetBalanceFormatterFactoryProtocol = AssetBalanceFormatterFactory()
    private let chainAsset: ChainAsset

    init(
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        iconGenerator: IconGenerating,
        chainAsset: ChainAsset
    ) {
        self.balanceViewModelFactory = balanceViewModelFactory
        self.iconGenerator = iconGenerator
        self.chainAsset = chainAsset
    }
}

extension SelectValidatorsConfirmRelaychainExistingViewModelFactory: SelectValidatorsConfirmViewModelFactoryProtocol {
    func buildAssetBalanceViewModel(
        viewModelState: SelectValidatorsConfirmViewModelState,
        priceData: PriceData?,
        balance: Decimal?
    ) -> LocalizableResource<AssetBalanceViewModelProtocol>? {
        guard let viewModelState = viewModelState as? SelectValidatorsConfirmRelaychainExistingViewModelState
        else {
            return nil
        }

        return balanceViewModelFactory.createAssetBalanceViewModel(
            viewModelState.confirmationModel?.amount ?? 0,
            balance: balance,
            priceData: priceData
        )
    }

    func buildHintsViewModel(
        viewModelState: SelectValidatorsConfirmViewModelState
    ) -> LocalizableResource<[TitleIconViewModel]>? {
        guard let viewModelState = viewModelState as? SelectValidatorsConfirmRelaychainExistingViewModelState,
              let duration = viewModelState.stakingDuration else {
            return nil
        }

        return LocalizableResource { locale in
            let eraDurationString = R.string.localizable.commonHoursFormat(
                format: duration.era.hoursFromSeconds,
                preferredLanguages: locale.rLanguages
            )

            let unlockingDurationString = R.string.localizable.commonDaysFormat(
                format: duration.unlocking.daysFromSeconds,
                preferredLanguages: locale.rLanguages
            )

            return [
                TitleIconViewModel(
                    title: R.string.localizable.stakingHintRewardsFormat(
                        eraDurationString,
                        preferredLanguages: locale.rLanguages
                    ),
                    icon: R.image.iconGeneralReward()
                ),
                TitleIconViewModel(
                    title: R.string.localizable.stakingHintUnstakeFormat(
                        unlockingDurationString,
                        preferredLanguages: locale.rLanguages
                    ),
                    icon: R.image.iconUnbond()
                ),
                TitleIconViewModel(
                    title: R.string.localizable.stakingHintNoRewards(
                        preferredLanguages: locale.rLanguages
                    ),
                    icon: R.image.iconNoReward()
                ),
                TitleIconViewModel(
                    title: R.string.localizable.stakingHintRedeem(
                        preferredLanguages: locale.rLanguages
                    ),
                    icon: R.image.iconRedeem()
                )
            ]
        }
    }

    func buildViewModel(
        viewModelState: SelectValidatorsConfirmViewModelState,
        asset _: AssetModel
    ) throws -> LocalizableResource<SelectValidatorsConfirmViewModel>? {
        guard let viewModelState = viewModelState as? SelectValidatorsConfirmRelaychainExistingViewModelState,
              let state = viewModelState.confirmationModel else {
            return nil
        }

        let icon = try? iconGenerator.generateFromAddress(state.wallet.address)

        let rewardViewModel: RewardDestinationTypeViewModel

        switch state.rewardDestination {
        case .restake:
            rewardViewModel = .restake
        case let .payout(account):
            let payoutIcon = try? iconGenerator.generateFromAddress(account.address)

            rewardViewModel = .payout(icon: payoutIcon, title: account.username, address: account.address)
        }

        return LocalizableResource { _ in
            SelectValidatorsConfirmViewModel(
                senderAddress: state.wallet.address,
                senderName: state.wallet.username,
                amount: nil,
                rewardDestination: rewardViewModel,
                validatorsCount: state.targets.count,
                maxValidatorCount: state.maxTargets,
                selectedCollatorViewModel: nil,
                stakeAmountViewModel: self.createStakedAmountViewModel(),
                poolName: nil
            )
        }
    }

    func buildFeeViewModel(
        viewModelState: SelectValidatorsConfirmViewModelState,
        priceData: PriceData?
    ) -> LocalizableResource<BalanceViewModelProtocol>? {
        guard let viewModelState = viewModelState as? SelectValidatorsConfirmRelaychainExistingViewModelState,
              let fee = viewModelState.fee else {
            return nil
        }

        return balanceViewModelFactory.balanceFromPrice(fee, priceData: priceData)
    }

    private func createStakedAmountViewModel() -> LocalizableResource<StakeAmountViewModel>? {
        let iconViewModel = chainAsset.assetDisplayInfo.icon.map { RemoteImageViewModel(url: $0) }

        return LocalizableResource { locale in
            let stakedString = R.string.localizable.stakingSelectValidatorsConfirmTitle(
                preferredLanguages: locale.rLanguages
            )
            let stakedAmountAttributedString = NSMutableAttributedString(string: stakedString)
            stakedAmountAttributedString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: R.color.colorGray() as Any,
                range: (stakedString as NSString).range(of: stakedString)
            )

            return StakeAmountViewModel(amountTitle: stakedAmountAttributedString, iconViewModel: iconViewModel)
        }
    }
}
