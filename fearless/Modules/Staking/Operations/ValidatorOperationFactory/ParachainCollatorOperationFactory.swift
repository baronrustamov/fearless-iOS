import Foundation
import FearlessUtils
import RobinHood
import BigInt

final class ParachainCollatorOperationFactory {
    let asset: AssetModel
    let chain: ChainModel
    let storageRequestFactory: StorageRequestFactoryProtocol
    let runtimeService: RuntimeCodingServiceProtocol
    let identityOperationFactory: IdentityOperationFactoryProtocol
    let subqueryOperationFactory: SubqueryRewardOperationFactoryProtocol
    let engine: JSONRPCEngine

    init(
        asset: AssetModel,
        chain: ChainModel,
        storageRequestFactory: StorageRequestFactoryProtocol,
        runtimeService: RuntimeCodingServiceProtocol,
        engine: JSONRPCEngine,
        identityOperationFactory: IdentityOperationFactoryProtocol,
        subqueryOperationFactory: SubqueryRewardOperationFactoryProtocol
    ) {
        self.asset = asset
        self.chain = chain
        self.storageRequestFactory = storageRequestFactory
        self.runtimeService = runtimeService
        self.engine = engine
        self.identityOperationFactory = identityOperationFactory
        self.subqueryOperationFactory = subqueryOperationFactory
    }

    func createStorageKeyOperation(from storagePath: StorageCodingPath) -> ClosureOperation<Data> {
        ClosureOperation<Data> {
            try StorageKeyFactory().key(from: storagePath)
        }
    }

    func createTopDelegationsOperation(
        dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>,
        accountIdsClosure: @escaping () throws -> [AccountId]
    ) -> CompoundOperationWrapper<[AccountAddress: ParachainStakingDelegations]> {
        let topDelegationsWrapper: CompoundOperationWrapper<[StorageResponse<ParachainStakingDelegations>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keyParams: accountIdsClosure,
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .topDelegations
            )

        topDelegationsWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        let mergeOperation = ClosureOperation<[AccountAddress: ParachainStakingDelegations]> { [weak self] in
            guard let strongSelf = self else {
                return [:]
            }

            let topDelegations = try topDelegationsWrapper.targetOperation.extractNoCancellableResultData()

            var metadataByAddress: [AccountAddress: ParachainStakingDelegations] = [:]
            try topDelegations.compactMap {
                let accountId = $0.key.getAccountIdFromKey(accountIdLenght: strongSelf.chain.accountIdLenght)
                let address = try AddressFactory.address(for: accountId, chainFormat: strongSelf.chain.chainFormat)
                if let metadata = $0.value {
                    metadataByAddress[address] = metadata
                }
            }

            return metadataByAddress
        }

        mergeOperation.addDependency(topDelegationsWrapper.targetOperation)

        return CompoundOperationWrapper(targetOperation: mergeOperation, dependencies: topDelegationsWrapper.allOperations)
    }

    func createAtStakeOperation(
        dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>,
        params: @escaping () throws -> [[NMapKeyParamProtocol]]
    ) -> CompoundOperationWrapper<[AccountAddress: ParachainStakingCollatorSnapshot]> {
        let atStakeWrapper: CompoundOperationWrapper<[StorageResponse<ParachainStakingCollatorSnapshot>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keyParams: params,
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .atStake
            )

        atStakeWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        let mergeOperation = ClosureOperation<[AccountAddress: ParachainStakingCollatorSnapshot]> { [weak self] in
            guard let strongSelf = self else {
                return [:]
            }

            let topDelegations = try atStakeWrapper.targetOperation.extractNoCancellableResultData()

            var metadataByAddress: [AccountAddress: ParachainStakingCollatorSnapshot] = [:]
            try topDelegations.compactMap {
                let accountId = $0.key.getAccountIdFromKey(accountIdLenght: strongSelf.chain.accountIdLenght)
                let address = try AddressFactory.address(for: accountId, chainFormat: strongSelf.chain.chainFormat)
                if let metadata = $0.value {
                    metadataByAddress[address] = metadata
                }
            }

            return metadataByAddress
        }

        mergeOperation.addDependency(atStakeWrapper.targetOperation)

        return CompoundOperationWrapper(targetOperation: mergeOperation, dependencies: atStakeWrapper.allOperations)
    }

    func createDelegatorStateOperation(
        dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>,
        accountIdsClosure: @escaping () throws -> [AccountId]
    ) -> CompoundOperationWrapper<[AccountAddress: ParachainStakingDelegatorState]> {
        let topDelegationsWrapper: CompoundOperationWrapper<[StorageResponse<ParachainStakingDelegatorState>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keyParams: accountIdsClosure,
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .delegatorStake
            )

        topDelegationsWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        let mergeOperation = ClosureOperation<[AccountAddress: ParachainStakingDelegatorState]> { [weak self] in
            guard let strongSelf = self else {
                return [:]
            }

            let topDelegations = try topDelegationsWrapper.targetOperation.extractNoCancellableResultData()

            var metadataByAddress: [AccountAddress: ParachainStakingDelegatorState] = [:]
            try topDelegations.compactMap {
                let accountId = $0.key.getAccountIdFromKey(accountIdLenght: strongSelf.chain.accountIdLenght)
                let address = try AddressFactory.address(for: accountId, chainFormat: strongSelf.chain.chainFormat)
                if let metadata = $0.value {
                    metadataByAddress[address] = metadata
                }
            }

            return metadataByAddress
        }

        mergeOperation.addDependency(topDelegationsWrapper.targetOperation)

        return CompoundOperationWrapper(targetOperation: mergeOperation, dependencies: topDelegationsWrapper.allOperations)
    }

    func createCollatorInfoOperation(
        dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>,
        accountIdsClosure: @escaping () throws -> [AccountId]
    ) -> CompoundOperationWrapper<[AccountAddress: ParachainStakingCandidateMetadata]> {
        let candidateInfoWrapper: CompoundOperationWrapper<[StorageResponse<ParachainStakingCandidateMetadata>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keyParams: accountIdsClosure,
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .candidateInfo
            )

        candidateInfoWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        let mergeOperation = ClosureOperation<[AccountAddress: ParachainStakingCandidateMetadata]> { [weak self] in
            guard let strongSelf = self else {
                return [:]
            }

            let candidateInfos = try candidateInfoWrapper.targetOperation.extractNoCancellableResultData()

            var metadataByAddress: [AccountAddress: ParachainStakingCandidateMetadata] = [:]
            try candidateInfos.compactMap {
                let accountId = $0.key.getAccountIdFromKey(accountIdLenght: strongSelf.chain.accountIdLenght)
                let address = try AddressFactory.address(for: accountId, chainFormat: strongSelf.chain.chainFormat)
                if let metadata = $0.value {
                    metadataByAddress[address] = metadata
                }
            }

            return metadataByAddress
        }

        mergeOperation.addDependency(candidateInfoWrapper.targetOperation)

        return CompoundOperationWrapper(targetOperation: mergeOperation, dependencies: candidateInfoWrapper.allOperations)
    }

    func createCandidatePoolOperation(dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>) -> CompoundOperationWrapper<[StorageResponse<[ParachainStakingCandidate]>]> {
        guard let candidatePoolKey = try? StorageKeyFactory().key(from: .candidatePool) else {
            return CompoundOperationWrapper(targetOperation: ClosureOperation { [] })
        }

        let candidatePoolWrapper: CompoundOperationWrapper<[StorageResponse<[ParachainStakingCandidate]>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keys: { [candidatePoolKey] },
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .candidatePool
            )

        candidatePoolWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        return candidatePoolWrapper
    }

    func createSelectedCandidatesOperation(dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>) -> CompoundOperationWrapper<[StorageResponse<[AccountId]>]> {
        guard let selectedCandidatesKey = try? StorageKeyFactory().key(from: .selectedCandidates) else {
            return CompoundOperationWrapper(targetOperation: ClosureOperation { [] })
        }

        let selectedCandidatesWrapper: CompoundOperationWrapper<[StorageResponse<[AccountId]>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keys: { [selectedCandidatesKey] },
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .selectedCandidates
            )

        selectedCandidatesWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        return selectedCandidatesWrapper
    }

    func createDelegationScheduledRequestsOperation(
        dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>,
        accountIdsClosure: @escaping () throws -> [AccountId]
    ) -> CompoundOperationWrapper<[StorageResponse<[ParachainStakingScheduledRequest]>]> {
        let delegationScheduledRequestsWrapper: CompoundOperationWrapper<[StorageResponse<[ParachainStakingScheduledRequest]>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keyParams: accountIdsClosure,
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .delegationScheduledRequests
            )

        delegationScheduledRequestsWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        return delegationScheduledRequestsWrapper
    }

    func createRoundOperation(dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>) -> CompoundOperationWrapper<[StorageResponse<ParachainStakingRoundInfo>]> {
        guard let roundKey = try? StorageKeyFactory().key(from: .round) else {
            return CompoundOperationWrapper(targetOperation: ClosureOperation { [] })
        }

        let candidatePoolWrapper: CompoundOperationWrapper<[StorageResponse<ParachainStakingRoundInfo>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keys: { [roundKey] },
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .round
            )

        candidatePoolWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        return candidatePoolWrapper
    }

    func createCommissionOperation(
        dependingOn runtimeOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) -> CompoundOperationWrapper<[StorageResponse<String>]> {
        guard let roundKey = try? StorageKeyFactory().key(from: .collatorCommission) else {
            return CompoundOperationWrapper(targetOperation: ClosureOperation { [] })
        }

        let candidatePoolWrapper: CompoundOperationWrapper<[StorageResponse<String>]> =
            storageRequestFactory.queryItems(
                engine: engine,
                keys: { [roundKey] },
                factory: { try runtimeOperation.extractNoCancellableResultData() },
                storagePath: .collatorCommission
            )

        candidatePoolWrapper.allOperations.forEach { $0.addDependency(runtimeOperation) }

        return candidatePoolWrapper
    }
}

extension ParachainCollatorOperationFactory {
    func candidateInfos(for candidateIdsOperation: CompoundOperationWrapper<[AccountId]>) -> CompoundOperationWrapper<[ParachainStakingCandidateInfo]?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()

        let candidatePoolOperation = createCandidatePoolOperation(dependingOn: runtimeOperation)

        let accountIdsClosure: () throws -> [AccountId] = {
            try candidateIdsOperation.targetOperation.extractNoCancellableResultData()
        }

        let identityWrapper = identityOperationFactory.createIdentityWrapper(
            for: accountIdsClosure,
            engine: engine,
            runtimeService: runtimeService,
            chain: chain
        )

        let infoWrapper = createCollatorInfoOperation(
            dependingOn: runtimeOperation,
            accountIdsClosure: accountIdsClosure
        )

        let aprOperation = subqueryOperationFactory.createAprOperation(for: accountIdsClosure)

        identityWrapper.allOperations.forEach { $0.addDependency(candidateIdsOperation.targetOperation) }
        infoWrapper.allOperations.forEach { $0.addDependency(candidateIdsOperation.targetOperation) }
        aprOperation.addDependency(candidateIdsOperation.targetOperation)

        let mergeOperation = ClosureOperation<[ParachainStakingCandidateInfo]?> {
            let identities = try identityWrapper.targetOperation.extractNoCancellableResultData()
            let infos = try infoWrapper.targetOperation.extractNoCancellableResultData()
            let collatorsApr = try? aprOperation.extractNoCancellableResultData()

            let candidatePool = try candidatePoolOperation.targetOperation.extractNoCancellableResultData().first?.value
            let candidateIds = try candidateIdsOperation.targetOperation.extractNoCancellableResultData()

            let candidateInfos: [ParachainStakingCandidateInfo]? = try candidatePool?
                .filter { candidateIds.contains($0.owner) == true }
                .compactMap { [weak self] collator in
                    guard let strongSelf = self else {
                        return nil
                    }

                    let address = try AddressFactory.address(
                        for: collator.owner,
                        chainFormat: strongSelf.chain.chainFormat
                    )

                    let subqueryData = collatorsApr?.collatorRounds.nodes.first(where: { $0.collatorId == address })

                    return ParachainStakingCandidateInfo(
                        address: address,
                        owner: collator.owner,
                        amount: collator.amount,
                        metadata: infos[address],
                        identity: identities[address],
                        subqueryData: subqueryData
                    )
                }

            return candidateInfos
        }

        mergeOperation.addDependency(aprOperation)
        mergeOperation.addDependency(candidatePoolOperation.targetOperation)
        mergeOperation.addDependency(candidateIdsOperation.targetOperation)
        mergeOperation.addDependency(infoWrapper.targetOperation)
        mergeOperation.addDependency(identityWrapper.targetOperation)

        var dependencies: [Operation] = []
        dependencies.append(runtimeOperation)
        dependencies.append(contentsOf: candidatePoolOperation.allOperations)
        dependencies.append(contentsOf: candidateIdsOperation.allOperations)
        dependencies.append(contentsOf: identityWrapper.allOperations)
        dependencies.append(contentsOf: infoWrapper.allOperations)
        dependencies.append(aprOperation)

        return CompoundOperationWrapper(targetOperation: mergeOperation, dependencies: dependencies)
    }

    func allElectedOperation() -> CompoundOperationWrapper<[ParachainStakingCandidateInfo]?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()

        let candidatePoolOperation = createCandidatePoolOperation(dependingOn: runtimeOperation)
        let selectedCandidatesOperation = createSelectedCandidatesOperation(dependingOn: runtimeOperation)

        let accountIdsClosure: () throws -> [AccountId] = {
            try selectedCandidatesOperation.targetOperation.extractNoCancellableResultData().first?.value ?? []
        }

        let aprOperation = subqueryOperationFactory.createAprOperation(for: accountIdsClosure)

        let identityWrapper = identityOperationFactory.createIdentityWrapper(
            for: accountIdsClosure,
            engine: engine,
            runtimeService: runtimeService,
            chain: chain
        )

        let infoWrapper = createCollatorInfoOperation(dependingOn: runtimeOperation, accountIdsClosure: accountIdsClosure)

        identityWrapper.allOperations.forEach { $0.addDependency(selectedCandidatesOperation.targetOperation) }
        infoWrapper.allOperations.forEach { $0.addDependency(selectedCandidatesOperation.targetOperation) }
        aprOperation.addDependency(selectedCandidatesOperation.targetOperation)

        let mergeOperation = ClosureOperation<[ParachainStakingCandidateInfo]?> {
            let identities = try identityWrapper.targetOperation.extractNoCancellableResultData()
            let infos = try infoWrapper.targetOperation.extractNoCancellableResultData()
            let collatorsApr = try? aprOperation.extractNoCancellableResultData()

            let candidatePool = try candidatePoolOperation.targetOperation.extractNoCancellableResultData().first?.value
            let selectedCandidatesIds = try selectedCandidatesOperation.targetOperation.extractNoCancellableResultData().first?.value

            let selectedCandidates: [ParachainStakingCandidateInfo]? = try candidatePool?
                .filter { selectedCandidatesIds?.contains($0.owner) == true }
                .compactMap { [weak self] collator in
                    guard let strongSelf = self else {
                        return nil
                    }

                    let address = try AddressFactory.address(
                        for: collator.owner,
                        chainFormat: strongSelf.chain.chainFormat
                    )

                    let subqueryData = collatorsApr?.collatorRounds.nodes.first(where: { $0.collatorId.lowercased() == address.lowercased() && $0.apr != nil })

                    return ParachainStakingCandidateInfo(
                        address: address,
                        owner: collator.owner,
                        amount: collator.amount,
                        metadata: infos[address],
                        identity: identities[address],
                        subqueryData: subqueryData
                    )
                }

            return selectedCandidates
        }

        mergeOperation.addDependency(aprOperation)
        mergeOperation.addDependency(candidatePoolOperation.targetOperation)
        mergeOperation.addDependency(selectedCandidatesOperation.targetOperation)
        mergeOperation.addDependency(infoWrapper.targetOperation)
        mergeOperation.addDependency(identityWrapper.targetOperation)

        var dependencies: [Operation] = []
        dependencies.append(runtimeOperation)
        dependencies.append(contentsOf: candidatePoolOperation.allOperations)
        dependencies.append(contentsOf: selectedCandidatesOperation.allOperations)
        dependencies.append(contentsOf: identityWrapper.allOperations)
        dependencies.append(contentsOf: infoWrapper.allOperations)
        dependencies.append(aprOperation)

        return CompoundOperationWrapper(targetOperation: mergeOperation, dependencies: dependencies)
    }

    func collatorInfoOperation(accountId: AccountId) -> CompoundOperationWrapper<ParachainStakingCandidateMetadata?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()
        let candidateInfoOperation = createCollatorInfoOperation(dependingOn: runtimeOperation) {
            [accountId]
        }

        let mapOperation = ClosureOperation<ParachainStakingCandidateMetadata?> {
            try candidateInfoOperation.targetOperation.extractNoCancellableResultData().first?.value
        }

        mapOperation.addDependency(candidateInfoOperation.targetOperation)

        let dependencies = [runtimeOperation] + candidateInfoOperation.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    func collatorTopDelegations(accountIdsClosure: @escaping () throws -> [AccountId]) -> CompoundOperationWrapper<[AccountAddress: ParachainStakingDelegations]?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()
        let topDelegationsWrapper = createTopDelegationsOperation(
            dependingOn: runtimeOperation,
            accountIdsClosure: accountIdsClosure
        )

        let mapOperation = ClosureOperation<[AccountAddress: ParachainStakingDelegations]?> {
            try topDelegationsWrapper.targetOperation.extractNoCancellableResultData()
        }

        mapOperation.addDependency(topDelegationsWrapper.targetOperation)

        let dependencies = [runtimeOperation] + topDelegationsWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    func collatorAtStake(
        collatorAccountId: AccountId
    ) -> CompoundOperationWrapper<[AccountAddress: ParachainStakingCollatorSnapshot]?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()
        let roundOperation = createRoundOperation(dependingOn: runtimeOperation)

        let paramsClosure: () throws -> [[NMapKeyParamProtocol]] = {
            let round = try roundOperation.targetOperation.extractNoCancellableResultData().first?.value?.current ?? 0

            return [[NMapKeyParam(value: round)], [NMapKeyParam(value: collatorAccountId)]]
        }

        let atStakeWrapper = createAtStakeOperation(
            dependingOn: runtimeOperation,
            params: paramsClosure
        )

        atStakeWrapper.addDependency(wrapper: roundOperation)

        let mapOperation = ClosureOperation<[AccountAddress: ParachainStakingCollatorSnapshot]?> {
            try atStakeWrapper.targetOperation.extractNoCancellableResultData()
        }

        mapOperation.addDependency(atStakeWrapper.targetOperation)
        mapOperation.addDependency(roundOperation.targetOperation)

        let dependencies = [runtimeOperation] + atStakeWrapper.allOperations + roundOperation.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    func delegatorState(accountIdsClosure: @escaping () throws -> [AccountId]) -> CompoundOperationWrapper<[AccountAddress: ParachainStakingDelegatorState]?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()
        let delegatorStateWrapper = createDelegatorStateOperation(
            dependingOn: runtimeOperation,
            accountIdsClosure: accountIdsClosure
        )

        let mapOperation = ClosureOperation<[AccountAddress: ParachainStakingDelegatorState]?> {
            try delegatorStateWrapper.targetOperation.extractNoCancellableResultData()
        }

        mapOperation.addDependency(delegatorStateWrapper.targetOperation)

        let dependencies = [runtimeOperation] + delegatorStateWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    func delegationScheduledRequests(accountIdsClosure: @escaping () throws -> [AccountId]) -> CompoundOperationWrapper<[ParachainStakingScheduledRequest]?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()
        let delegatorStateWrapper = createDelegationScheduledRequestsOperation(
            dependingOn: runtimeOperation,
            accountIdsClosure: accountIdsClosure
        )

        let mapOperation = ClosureOperation<[ParachainStakingScheduledRequest]?> {
            try delegatorStateWrapper.targetOperation.extractNoCancellableResultData().first?.value
        }

        mapOperation.addDependency(delegatorStateWrapper.targetOperation)

        let dependencies = [runtimeOperation] + delegatorStateWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    func round() -> CompoundOperationWrapper<ParachainStakingRoundInfo?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()
        let roundWrapper = createRoundOperation(dependingOn: runtimeOperation)

        let mapOperation = ClosureOperation<ParachainStakingRoundInfo?> {
            try roundWrapper.targetOperation.extractNoCancellableResultData().first?.value
        }

        mapOperation.addDependency(roundWrapper.targetOperation)

        let dependencies = [runtimeOperation] + roundWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    func commission() -> CompoundOperationWrapper<String?> {
        let runtimeOperation = runtimeService.fetchCoderFactoryOperation()
        let commissionWrapper = createCommissionOperation(dependingOn: runtimeOperation)

        let mapOperation = ClosureOperation<String?> {
            try commissionWrapper.targetOperation.extractNoCancellableResultData().first?.value
        }

        mapOperation.addDependency(commissionWrapper.targetOperation)

        let dependencies = [runtimeOperation] + commissionWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }
}
