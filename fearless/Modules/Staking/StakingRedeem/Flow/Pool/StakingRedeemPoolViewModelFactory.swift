import Foundation
import SoraFoundation
import FearlessUtils
import BigInt

final class StakingRedeemPoolViewModelFactory: StakingRedeemViewModelFactoryProtocol {
    private let asset: AssetModel
    private let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    private var iconGenerator: IconGenerating
    private lazy var formatterFactory = AssetBalanceFormatterFactory()

    init(
        asset: AssetModel,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        iconGenerator: IconGenerating
    ) {
        self.asset = asset
        self.balanceViewModelFactory = balanceViewModelFactory
        self.iconGenerator = iconGenerator
    }

    func buildViewModel(viewModelState: StakingRedeemViewModelState) -> StakingRedeemViewModel? {
        guard let poolViewModelState = viewModelState as? StakingRedeemPoolViewModelState else {
            return nil
        }

        guard let era = poolViewModelState.activeEra,
              let redeemable = poolViewModelState.stakeInfo?.redeemable(inEra: era) else {
            return nil
        }

        let redeemableDecimal = Decimal.fromSubstrateAmount(
            redeemable,
            precision: Int16(asset.precision)
        ) ?? 0.0

        let formatter = formatterFactory.createInputFormatter(for: asset.displayInfo)

        let amount = LocalizableResource { locale in
            formatter.value(for: locale).string(from: redeemableDecimal as NSNumber) ?? ""
        }

        let address = poolViewModelState.address ?? ""
        let senderIcon = try? iconGenerator.generateFromAddress(address)
        let title = LocalizableResource { locale in
            R.string.localizable.stakingRevokeTokens(preferredLanguages: locale.rLanguages)
        }

        return StakingRedeemViewModel(
            senderAddress: address,
            senderIcon: senderIcon,
            senderName: poolViewModelState.wallet.fetch(for: poolViewModelState.chainAsset.chain.accountRequest())?.name,
            amount: amount,
            title: title,
            collatorName: nil,
            collatorIcon: nil
        )
    }

    func buildAssetViewModel(
        viewModelState: StakingRedeemViewModelState,
        priceData: PriceData?
    ) -> LocalizableResource<AssetBalanceViewModelProtocol>? {
        guard let poolViewModelState = viewModelState as? StakingRedeemPoolViewModelState else {
            return nil
        }

        guard let era = poolViewModelState.activeEra,
              let redeemable = poolViewModelState.stakeInfo?.redeemable(inEra: era) else {
            return nil
        }

        let redeemableDecimal = Decimal.fromSubstrateAmount(
            redeemable,
            precision: Int16(asset.precision)
        ) ?? 0.0

        return balanceViewModelFactory.createAssetBalanceViewModel(
            redeemableDecimal,
            balance: redeemableDecimal,
            priceData: priceData
        )
    }

    func buildHints() -> LocalizableResource<[TitleIconViewModel]> {
        LocalizableResource { locale in
            var items = [TitleIconViewModel]()

            items.append(
                TitleIconViewModel(
                    title: R.string.localizable.stakingStakeLessHint(preferredLanguages: locale.rLanguages),
                    icon: R.image.iconInfoFilled()?.tinted(with: R.color.colorStrokeGray()!)
                )
            )

            return items
        }
    }
}
