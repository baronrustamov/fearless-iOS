import Foundation
import SoraFoundation
import SoraKeystore
import FearlessUtils

final class StakingRewardDetailsViewFactory: StakingRewardDetailsViewFactoryProtocol {
    static func createView(
        chain: ChainModel,
        asset: AssetModel,
        input: StakingRewardDetailsInput
    ) -> StakingRewardDetailsViewProtocol? {
        let balanceViewModelFactory = BalanceViewModelFactory(
            targetAssetInfo: asset.displayInfo,
            limit: StakingConstants.maxAmount
        )

        let viewModelFactory = StakingRewardDetailsViewModelFactory(
            balanceViewModelFactory: balanceViewModelFactory,
            iconGenerator: PolkadotIconGenerator()
        )
        let presenter = StakingRewardDetailsPresenter(
            chain: chain,
            input: input,
            viewModelFactory: viewModelFactory
        )
        let view = StakingRewardDetailsViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        let substrateStorageFacade = SubstrateDataStorageFacade.shared

        let priceLocalSubscriptionFactory = PriceProviderFactory(storageFacade: substrateStorageFacade)

        let interactor = StakingRewardDetailsInteractor(
            asset: asset,
            priceLocalSubscriptionFactory: priceLocalSubscriptionFactory
        )
        let wireframe = StakingRewardDetailsWireframe()

        presenter.view = view
        presenter.interactor = interactor
        presenter.wireframe = wireframe
        interactor.presenter = presenter

        return view
    }
}
