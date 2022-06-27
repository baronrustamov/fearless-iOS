import RobinHood

final class AccountInfoSubscriptionProviderWrapper: WalletLocalStorageSubscriber {
    enum Subscription {
        case usual(provider: StreamableProvider<ChainStorageItem>)
        case orml(provider: StreamableProvider<ChainStorageItem>)
    }

    var walletLocalSubscriptionFactory: WalletLocalSubscriptionFactoryProtocol
    weak var walletLocalSubscriptionHandler: WalletLocalSubscriptionHandler?

    init(factory: WalletLocalSubscriptionFactoryProtocol, handler: WalletLocalSubscriptionHandler) {
        walletLocalSubscriptionFactory = factory
        walletLocalSubscriptionHandler = handler
    }

    func subscribeAccountProvider(
        for accountId: AccountId,
        chainAsset: ChainAsset
    ) -> Subscription? {
        var subscription: Subscription?

        switch chainAsset.chainAssetType {
        case .normal:
            if let provider = subscribeToAccountInfoProvider(for: accountId, chainAsset: chainAsset) {
                subscription = .usual(provider: provider)
            }
        case
            .ormlChain,
            .ormlAsset,
            .foreignAsset,
            .stableAssetPoolToken,
            .liquidCrowdloan,
            .vToken,
            .vsToken,
            .stable:
            if let provider = subscribeToOrmlAccountInfoProvider(for: accountId, chainAsset: chainAsset) {
                subscription = .orml(provider: provider)
            }
        }

        return subscription
    }
}
