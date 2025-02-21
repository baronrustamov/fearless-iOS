import Foundation
import FearlessUtils
import RobinHood
import BigInt

protocol StakingUnbondSetupPoolStrategyOutput: AnyObject {
    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>)
    func didReceiveExistentialDeposit(result: Result<BigUInt, Error>)
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>)
    func didReceive(stakeInfo: StakingPoolMember?)
    func didReceive(error: Error)
    func didReceive(stakingDuration: StakingDuration)
}

final class StakingUnbondSetupPoolStrategy: RuntimeConstantFetching, AccountFetching {
    private(set) var stakingLocalSubscriptionFactory: RelaychainStakingLocalSubscriptionFactoryProtocol
    private let wallet: MetaAccountModel
    private let chainAsset: ChainAsset
    private var stakingPoolOperationFactory: StakingPoolOperationFactoryProtocol
    private let operationManager: OperationManagerProtocol
    let accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol
    private let feeProxy: ExtrinsicFeeProxyProtocol
    private weak var output: StakingUnbondSetupPoolStrategyOutput?
    private lazy var callFactory = SubstrateCallFactory()
    private let stakingDurationOperationFactory: StakingDurationOperationFactoryProtocol
    private let runtimeService: RuntimeCodingServiceProtocol

    init(
        stakingLocalSubscriptionFactory: RelaychainStakingLocalSubscriptionFactoryProtocol,
        accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol,
        operationManager: OperationManagerProtocol,
        feeProxy: ExtrinsicFeeProxyProtocol,
        wallet: MetaAccountModel,
        chainAsset: ChainAsset,
        output: StakingUnbondSetupPoolStrategyOutput?,
        extrinsicService: ExtrinsicServiceProtocol?,
        stakingPoolOperationFactory: StakingPoolOperationFactoryProtocol,
        stakingDurationOperationFactory: StakingDurationOperationFactoryProtocol,
        runtimeService: RuntimeCodingServiceProtocol
    ) {
        self.stakingLocalSubscriptionFactory = stakingLocalSubscriptionFactory
        self.accountInfoSubscriptionAdapter = accountInfoSubscriptionAdapter
        self.operationManager = operationManager
        self.feeProxy = feeProxy
        self.wallet = wallet
        self.chainAsset = chainAsset
        self.output = output
        self.extrinsicService = extrinsicService
        self.stakingPoolOperationFactory = stakingPoolOperationFactory
        self.stakingDurationOperationFactory = stakingDurationOperationFactory
        self.runtimeService = runtimeService
    }

    private var poolMemberProvider: AnyDataProvider<DecodedPoolMember>?
    private var accountInfoProvider: AnyDataProvider<DecodedAccountInfo>?
    private var extrinsicService: ExtrinsicServiceProtocol?

    private func fetchStakingDuration() {
        let durationOperation = stakingDurationOperationFactory.createDurationOperation(from: runtimeService)

        durationOperation.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let stakingDuration = try durationOperation.targetOperation.extractNoCancellableResultData()
                    self?.output?.didReceive(stakingDuration: stakingDuration)
                } catch {
                    self?.output?.didReceive(error: error)
                }
            }
        }

        operationManager.enqueue(operations: durationOperation.allOperations, in: .transient)
    }
}

extension StakingUnbondSetupPoolStrategy: StakingUnbondSetupStrategy {
    func estimateFee(builderClosure: ExtrinsicBuilderClosure?) {
        guard let builderClosure = builderClosure,
              let extrinsicService = extrinsicService,
              let amount = StakingConstants.maxAmount.toSubstrateAmount(
                  precision: Int16(chainAsset.asset.precision)
              ),
              let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId
        else {
            return
        }

        let unbondCall = callFactory.poolUnbond(accountId: accountId, amount: amount)

        feeProxy.estimateFee(
            using: extrinsicService,
            reuseIdentifier: unbondCall.callName,
            setupBy: builderClosure
        )
    }

    func setup() {
        if let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId {
            accountInfoSubscriptionAdapter.subscribe(
                chainAsset: chainAsset,
                accountId: accountId,
                handler: self
            )

            poolMemberProvider = subscribeToPoolMembers(for: accountId, chainAsset: chainAsset)
        }

        feeProxy.delegate = self

        fetchStakingDuration()
    }

    func estimateFee() {
        guard let extrinsicService = extrinsicService,
              let amount = StakingConstants.maxAmount.toSubstrateAmount(
                  precision: Int16(chainAsset.asset.precision)
              ),
              let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId else {
            return
        }

        let unbondCall = callFactory.poolUnbond(accountId: accountId, amount: amount)

        feeProxy.estimateFee(using: extrinsicService, reuseIdentifier: unbondCall.callName) { builder in
            try builder.adding(call: unbondCall)
        }

        feeProxy.delegate = self
    }

    func estimateFeeOld() {
        guard let extrinsicService = extrinsicService,
              let amount = StakingConstants.maxAmount.toSubstrateAmount(
                  precision: Int16(chainAsset.asset.precision)
              ),
              let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId else {
            return
        }

        let unbondCall = callFactory.poolUnbondOld(accountId: accountId, amount: amount)

        feeProxy.estimateFee(using: extrinsicService, reuseIdentifier: unbondCall.callName) { builder in
            try builder.adding(call: unbondCall)
        }

        feeProxy.delegate = self
    }
}

extension StakingUnbondSetupPoolStrategy: AccountInfoSubscriptionAdapterHandler {
    func handleAccountInfo(result: Result<AccountInfo?, Error>, accountId _: AccountId, chainAsset _: ChainAsset) {
        output?.didReceiveAccountInfo(result: result)
    }
}

extension StakingUnbondSetupPoolStrategy: RelaychainStakingLocalStorageSubscriber, RelaychainStakingLocalSubscriptionHandler, AnyProviderAutoCleaning {
    func handlePoolMember(
        result: Result<StakingPoolMember?, Error>,
        accountId _: AccountId,
        chainId _: ChainModel.Id
    ) {
        switch result {
        case let .success(poolMember):
            output?.didReceive(stakeInfo: poolMember)
        case let .failure(error):
            output?.didReceive(error: error)
        }
    }
}

extension StakingUnbondSetupPoolStrategy: ExtrinsicFeeProxyDelegate {
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>, for _: ExtrinsicFeeId) {
        output?.didReceiveFee(result: result)

        switch result {
        case .success:
            break
        case .failure:
            estimateFeeOld()
        }
    }
}
