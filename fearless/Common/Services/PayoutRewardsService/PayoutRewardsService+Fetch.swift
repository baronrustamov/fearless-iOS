import RobinHood
import FearlessUtils
import BigInt
import IrohaCrypto

struct PayoutSteps1To3Result {
    let currentEra: EraIndex
    let activeEra: EraIndex
    let historyDepth: UInt32
}

struct PayoutSteps4And5Result {
    let totalValidatorRewardByEra: [EraIndex: BigUInt]
    let validatorPointsDistributionByEra: [EraIndex: EraRewardPoints]
}

extension PayoutRewardsService {
    func createSteps1To3OperationWrapper(
        engine: JSONRPCEngine,
        codingFactoryOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) throws -> CompoundOperationWrapper<PayoutSteps1To3Result> {
        let currentEra = createCurrentEraWrapper(
            engine: engine,
            codingFactory: { try codingFactoryOperation.extractNoCancellableResultData() }
        )
        currentEra.allOperations.forEach { $0.addDependency(codingFactoryOperation) }

        let activeEra = createActiveEraWrapper(
            engine: engine,
            codingFactory: { try codingFactoryOperation.extractNoCancellableResultData() }
        )
        activeEra.allOperations.forEach { $0.addDependency(codingFactoryOperation) }

        let historyDepth = createHistoryDepthWrapper(
            engine: engine,
            codingFactory: { try codingFactoryOperation.extractNoCancellableResultData() }
        )
        historyDepth.allOperations.forEach { $0.addDependency(codingFactoryOperation) }

        let mergeOperation = ClosureOperation<PayoutSteps1To3Result> {
            guard
                let currentEra = try currentEra.targetOperation.extractNoCancellableResultData()
                .first?.value?.value,
                let activeEra = try activeEra.targetOperation.extractNoCancellableResultData()
                .first?.value?.index,
                let historyDepth = try historyDepth.targetOperation.extractNoCancellableResultData()
                .first?.value?.value
            else {
                throw PayoutError.unknown
            }

            return PayoutSteps1To3Result(
                currentEra: currentEra,
                activeEra: activeEra,
                historyDepth: historyDepth
            )
        }

        currentEra.allOperations.forEach { mergeOperation.addDependency($0) }
        activeEra.allOperations.forEach { mergeOperation.addDependency($0) }
        historyDepth.allOperations.forEach { mergeOperation.addDependency($0) }

        return CompoundOperationWrapper(
            targetOperation: mergeOperation,
            dependencies: currentEra.allOperations + activeEra.allOperations + historyDepth.allOperations
        )
    }

    func createSteps4And5OperationWrapper(
        dependingOn baseOperation: BaseOperation<PayoutSteps1To3Result>,
        engine: JSONRPCEngine,
        codingFactoryOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) throws -> CompoundOperationWrapper<PayoutSteps4And5Result> {
        let totalRewardOperation = try createFetchTotalRewardOperation(
            dependingOn: baseOperation,
            engine: engine,
            codingFactoryOperation: codingFactoryOperation
        )
        totalRewardOperation.allOperations.forEach { $0.addDependency(codingFactoryOperation) }

        let validatorRewardPoints = try createValidatorRewardPointsOperation(
            dependingOn: baseOperation,
            engine: engine,
            codingFactoryOperation: codingFactoryOperation
        )
        validatorRewardPoints.allOperations.forEach { $0.addDependency(codingFactoryOperation) }

        let mergeOperation = ClosureOperation<PayoutSteps4And5Result> {
            let totalValidatorRewardByEra = try totalRewardOperation
                .targetOperation.extractNoCancellableResultData()
            let validatorRewardPoints = try validatorRewardPoints
                .targetOperation.extractNoCancellableResultData()

            return PayoutSteps4And5Result(
                totalValidatorRewardByEra: totalValidatorRewardByEra,
                validatorPointsDistributionByEra: validatorRewardPoints
            )
        }

        let mergeOperationDependencies = totalRewardOperation.allOperations + validatorRewardPoints.allOperations
        mergeOperationDependencies.forEach { mergeOperation.addDependency($0) }

        return CompoundOperationWrapper(
            targetOperation: mergeOperation,
            dependencies: mergeOperationDependencies
        )
    }

    func createFetchTotalRewardOperation(
        dependingOn basedOperation: BaseOperation<PayoutSteps1To3Result>,
        engine: JSONRPCEngine,
        codingFactoryOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) throws -> CompoundOperationWrapper<[EraIndex: BigUInt]> {
        let mapOperation = MapKeyEncodingOperation<String>(
            path: .totalValidatorReward,
            storageKeyFactory: StorageKeyFactory()
        )

        mapOperation.configurationBlock = {
            do {
                let result = try basedOperation.extractNoCancellableResultData()
                let eras = result.currentEra - result.historyDepth ... result.activeEra - 1
                mapOperation.codingFactory = try codingFactoryOperation.extractNoCancellableResultData()
                mapOperation.keyParams = eras.map(\.description)
            } catch {
                mapOperation.result = .failure(error)
            }
        }

        let requestFactory = StorageRequestFactory(remoteFactory: StorageKeyFactory())

        let wrapper: CompoundOperationWrapper<[StorageResponse<StringScaleMapper<BigUInt>>]> =
            requestFactory.queryItems(
                engine: engine,
                keys: { try mapOperation.extractNoCancellableResultData() },
                factory: { try codingFactoryOperation.extractNoCancellableResultData() },
                storagePath: .totalValidatorReward
            )
        wrapper.allOperations.forEach { $0.addDependency(mapOperation) }

        let mergeOperation = ClosureOperation<[EraIndex: BigUInt]> {
            let result = try basedOperation.extractNoCancellableResultData()
            let eras = Array(result.currentEra - result.historyDepth ... result.activeEra - 1)
            let keys = try mapOperation.extractNoCancellableResultData()

            let results = try wrapper.targetOperation.extractNoCancellableResultData()
                .reduce(into: [EraIndex: BigUInt]()) { dict, item in
                    guard let eraIndex = keys.firstIndex(of: item.key) else {
                        return
                    }
                    guard let itemValue = item.value?.value else {
                        return
                    }

                    let era = eras[eraIndex]
                    dict[era] = itemValue
                }
            return results
        }
        wrapper.allOperations.forEach { mergeOperation.addDependency($0) }

        return CompoundOperationWrapper(
            targetOperation: mergeOperation,
            dependencies: [mapOperation] + wrapper.allOperations
        )
    }

    func createValidatorRewardPointsOperation(
        dependingOn baseOperation: BaseOperation<PayoutSteps1To3Result>,
        engine: JSONRPCEngine,
        codingFactoryOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) throws -> CompoundOperationWrapper<[EraIndex: EraRewardPoints]> {
        let mapOperation = MapKeyEncodingOperation<String>(
            path: .rewardPointsPerValidator,
            storageKeyFactory: StorageKeyFactory()
        )

        mapOperation.configurationBlock = {
            do {
                let result = try baseOperation.extractNoCancellableResultData()
                let eras = result.currentEra - result.historyDepth ... result.activeEra - 1
                mapOperation.codingFactory = try codingFactoryOperation.extractNoCancellableResultData()
                mapOperation.keyParams = eras.map(\.description)
            } catch {
                mapOperation.result = .failure(error)
            }
        }

        let requestFactory = StorageRequestFactory(remoteFactory: StorageKeyFactory())

        let wrapper: CompoundOperationWrapper<[StorageResponse<EraRewardPoints>]> =
            requestFactory.queryItems(
                engine: engine,
                keys: { try mapOperation.extractNoCancellableResultData() },
                factory: { try codingFactoryOperation.extractNoCancellableResultData() },
                storagePath: .rewardPointsPerValidator
            )
        wrapper.allOperations.forEach { $0.addDependency(mapOperation) }

        let mergeOperation = ClosureOperation<[EraIndex: EraRewardPoints]> {
            let result = try baseOperation.extractNoCancellableResultData()
            let eras = Array(result.currentEra - result.historyDepth ... result.activeEra - 1)
            let keys = try mapOperation.extractNoCancellableResultData()

            let results = try wrapper.targetOperation.extractNoCancellableResultData()
                .reduce(into: [EraIndex: EraRewardPoints]()) { dict, item in
                    guard let eraIndex = keys.firstIndex(of: item.key) else {
                        return
                    }
                    guard let itemValue = item.value else {
                        return
                    }

                    let era = eras[eraIndex]
                    dict[era] = itemValue
                }
            return results
        }
        wrapper.allOperations.forEach { mergeOperation.addDependency($0) }

        return CompoundOperationWrapper(
            targetOperation: mergeOperation,
            dependencies: [mapOperation] + wrapper.allOperations
        )
    }

    private func createCurrentEraWrapper(
        engine: JSONRPCEngine,
        codingFactory: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) -> CompoundOperationWrapper<[StorageResponse<StringScaleMapper<UInt32>>]> {
        let keyFactory = StorageKeyFactory()
        let requestFactory = StorageRequestFactory(remoteFactory: keyFactory)

        let queryWrapper: CompoundOperationWrapper<[StorageResponse<StringScaleMapper<UInt32>>]> =
            requestFactory.queryItems(
                engine: engine,
                keys: { [try keyFactory.currentEra()] },
                factory: codingFactory,
                storagePath: .currentEra
            )
        return queryWrapper
    }

    private func createActiveEraWrapper(
        engine: JSONRPCEngine,
        codingFactory: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) -> CompoundOperationWrapper<[StorageResponse<ActiveEraInfo>]> {
        let keyFactory = StorageKeyFactory()
        let requestFactory = StorageRequestFactory(remoteFactory: keyFactory)

        return requestFactory.queryItems(
            engine: engine,
            keys: { [try keyFactory.activeEra()] },
            factory: codingFactory,
            storagePath: .activeEra
        )
    }

    private func createHistoryDepthWrapper(
        engine: JSONRPCEngine,
        codingFactory: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) -> CompoundOperationWrapper<[StorageResponse<StringScaleMapper<UInt32>>]> {
        let keyFactory = StorageKeyFactory()
        let requestFactory = StorageRequestFactory(remoteFactory: keyFactory)

        return requestFactory.queryItems(
            engine: engine,
            keys: { [try keyFactory.historyDepth()] },
            factory: codingFactory,
            storagePath: .historyDepth
        )
    }

    func createControllersByValidatorStashOperation(
        dependingOn validatorStashOperation: BaseOperation<Set<String>>,
        chain: Chain,
        engine: JSONRPCEngine,
        codingFactoryOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) throws -> CompoundOperationWrapper<[Data]> {
        let mapOperation = MapKeyEncodingOperation<Data>(
            path: .controller,
            storageKeyFactory: StorageKeyFactory()
        )

        mapOperation.configurationBlock = {
            do {
                let addresses = try validatorStashOperation.extractNoCancellableResultData()
                let addressFactory = SS58AddressFactory()
                let accountIds = addresses
                    .compactMap { try? addressFactory.accountId(fromAddress: $0, type: chain.addressType) }
                mapOperation.codingFactory = try codingFactoryOperation.extractNoCancellableResultData()
                mapOperation.keyParams = accountIds
            } catch {
                mapOperation.result = .failure(error)
            }
        }

        let requestFactory = StorageRequestFactory(remoteFactory: StorageKeyFactory())

        let wrapper: CompoundOperationWrapper<[StorageResponse<Data>]> =
            requestFactory.queryItems(
                engine: engine,
                keys: { try mapOperation.extractNoCancellableResultData() },
                factory: { try codingFactoryOperation.extractNoCancellableResultData() },
                storagePath: .controller
            )
        wrapper.allOperations.forEach { $0.addDependency(mapOperation) }

        let mergeOperation = ClosureOperation<[Data]> {
            try wrapper.targetOperation.extractNoCancellableResultData()
                .compactMap(\.value)
        }
        wrapper.allOperations.forEach { mergeOperation.addDependency($0) }

        return CompoundOperationWrapper(
            targetOperation: mergeOperation,
            dependencies: [mapOperation] + wrapper.allOperations
        )
    }

    func createLedgerInfoOperation(
        dependingOn controllersOperation: BaseOperation<[Data]>,
        engine: JSONRPCEngine,
        codingFactoryOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) throws -> CompoundOperationWrapper<[DyStakingLedger]> {
        let mapOperation = MapKeyEncodingOperation<Data>(
            path: .stakingLedger,
            storageKeyFactory: StorageKeyFactory()
        )

        mapOperation.configurationBlock = {
            do {
                let controllers = try controllersOperation.extractNoCancellableResultData()
                mapOperation.codingFactory = try codingFactoryOperation.extractNoCancellableResultData()
                mapOperation.keyParams = controllers
            } catch {
                mapOperation.result = .failure(error)
            }
        }

        let requestFactory = StorageRequestFactory(remoteFactory: StorageKeyFactory())

        let wrapper: CompoundOperationWrapper<[StorageResponse<DyStakingLedger>]> =
            requestFactory.queryItems(
                engine: engine,
                keys: { try mapOperation.extractNoCancellableResultData() },
                factory: { try codingFactoryOperation.extractNoCancellableResultData() },
                storagePath: .stakingLedger
            )
        wrapper.allOperations.forEach { $0.addDependency(mapOperation) }

        let mergeOperation = ClosureOperation<[DyStakingLedger]> {
            try wrapper.targetOperation.extractNoCancellableResultData()
                .compactMap(\.value)
        }
        wrapper.allOperations.forEach { mergeOperation.addDependency($0) }

        return CompoundOperationWrapper(
            targetOperation: mergeOperation,
            dependencies: [mapOperation] + wrapper.allOperations
        )
    }
}
