//import XCTest
//@testable import fearless
//import Cuckoo
//import RobinHood
//import FearlessUtils
//import SoraKeystore
//import SoraFoundation
//
//class StakingUnbondConfirmTests: XCTestCase {
//
//    func testUnbondingConfirmationSuccess() throws {
//        // given
//
//        let view = MockStakingUnbondConfirmViewProtocol()
//        let wireframe = MockStakingUnbondConfirmWireframeProtocol()
//
//        // when
//
//        let presenter = try setupPresenter(for: 1.0, view: view, wireframe: wireframe)
//
//        let completionExpectation = XCTestExpectation()
//
//        stub(view) { stub in
//            when(stub).didReceiveAsset(viewModel: any()).thenDoNothing()
//
//            when(stub).didReceiveFee(viewModel: any()).thenDoNothing()
//
//            when(stub).didReceiveConfirmation(viewModel: any()).thenDoNothing()
//
//            when(stub).localizationManager.get.then { nil }
//
//            when(stub).didStartLoading().thenDoNothing()
//
//            when(stub).didStopLoading().thenDoNothing()
//        }
//
//        stub(wireframe) { stub in
//            when(stub).complete(from: any()).then { _ in
//                completionExpectation.fulfill()
//            }
//        }
//
//        presenter.confirm()
//
//        // then
//
//        wait(for: [completionExpectation], timeout: 10.0)
//    }
//
//    private func setupPresenter(
//        for inputAmount: Decimal,
//        view: MockStakingUnbondConfirmViewProtocol,
//        wireframe: MockStakingUnbondConfirmWireframeProtocol
//    ) throws -> StakingUnbondConfirmPresenterProtocol {
//        // given
//
//        let settings = InMemorySettingsManager()
//        let keychain = InMemoryKeychain()
//
//        let chain = Chain.westend
//        try AccountCreationHelper.createAccountFromMnemonic(cryptoType: .sr25519,
//                                                            networkType: chain,
//                                                            keychain: keychain,
//                                                            settings: settings)
//
//        let primitiveFactory = WalletPrimitiveFactory(settings: settings)
//        let asset = primitiveFactory.createAssetForAddressType(chain.addressType)
//        let assetId = WalletAssetId(
//            rawValue: asset.identifier
//        )!
//
//        let storageFacade = SubstrateStorageTestFacade()
//        let operationManager = OperationManager()
//
//        let nominatorAddress = settings.selectedAccount!.address
//        let cryptoType = settings.selectedAccount!.cryptoType
//
//        let singleValueProviderFactory = SingleValueProviderFactoryStub.westendNominatorStub()
//
//        // save stash item
//
//        let stashItem = StashItem(stash: nominatorAddress, controller: nominatorAddress)
//        let repository: CoreDataRepository<StashItem, CDStashItem> =
//            storageFacade.createRepository()
//
//        let operationQueue = OperationQueue()
//        let saveStashItemOperation = repository.saveOperation({ [stashItem] }, { [] })
//        operationQueue.addOperations([saveStashItemOperation], waitUntilFinished: true)
//
//        let substrateProviderFactory = SubstrateDataProviderFactory(
//            facade: storageFacade,
//            operationManager: operationManager
//        )
//
//        let runtimeCodingService = try RuntimeCodingServiceStub.createWestendService()
//
//        let accountRepository = AccountRepositoryFactory.createRepository(for: UserDataStorageTestFacade())
//
//        // save controller
//        let controllerItem = settings.selectedAccount!
//        let saveControllerOperation = accountRepository.saveOperation({ [controllerItem] }, { [] })
//        operationQueue.addOperations([saveControllerOperation], waitUntilFinished: true)
//
//        let extrinsicServiceFactory = ExtrinsicServiceFactoryStub(
//            extrinsicService: ExtrinsicServiceStub.dummy(),
//            signingWraper: try DummySigner(cryptoType: cryptoType)
//        )
//
//        let interactor = StakingUnbondConfirmInteractor(
//            assetId: assetId,
//            chain: chain,
//            singleValueProviderFactory: singleValueProviderFactory,
//            substrateProviderFactory: substrateProviderFactory,
//            extrinsicServiceFactory: extrinsicServiceFactory,
//            feeProxy: ExtrinsicFeeProxy(),
//            accountRepository: accountRepository,
//            settings: settings,
//            runtimeService: runtimeCodingService,
//            operationManager: operationManager
//        )
//
//        let balanceViewModelFactory = BalanceViewModelFactory(
//            walletPrimitiveFactory: primitiveFactory,
//            selectedAddressType: chain.addressType,
//            limit: StakingConstants.maxAmount
//        )
//
//        let confirmViewModelFactory = StakingUnbondConfirmViewModelFactory(asset: asset)
//
//        let presenter = StakingUnbondConfirmPresenter(
//            interactor: interactor,
//            wireframe: wireframe,
//            inputAmount: inputAmount,
//            confirmViewModelFactory: confirmViewModelFactory,
//            balanceViewModelFactory: balanceViewModelFactory,
//            dataValidatingFactory: StakingDataValidatingFactory(presentable: wireframe),
//            chain: chain
//        )
//
//        presenter.view = view
//        interactor.presenter = presenter
//
//        // when
//
//        let feeExpectation = XCTestExpectation()
//        let assetExpectation = XCTestExpectation()
//        let confirmViewModelExpectation = XCTestExpectation()
//
//        stub(view) { stub in
//            when(stub).didReceiveAsset(viewModel: any()).then { viewModel in
//                if let balance = viewModel.value(for: Locale.current).balance, !balance.isEmpty {
//                    assetExpectation.fulfill()
//                }
//            }
//
//            when(stub).didReceiveFee(viewModel: any()).then { viewModel in
//                if let fee = viewModel?.value(for: Locale.current).amount, !fee.isEmpty {
//                    feeExpectation.fulfill()
//                }
//            }
//
//            when(stub).didReceiveConfirmation(viewModel: any()).then { viewModel in
//                confirmViewModelExpectation.fulfill()
//            }
//        }
//
//        presenter.setup()
//
//        // then
//
//        wait(for: [assetExpectation, feeExpectation, confirmViewModelExpectation], timeout: 10)
//
//        return presenter
//    }
//}
