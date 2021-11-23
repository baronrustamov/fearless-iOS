import UIKit
import IrohaCrypto
import FearlessUtils
import RobinHood
import SoraKeystore

extension AddAccount {
    final class AccountImportInteractor: BaseAccountImportInteractor {
        private(set) var settings: SelectedWalletSettings
        let eventCenter: EventCenterProtocol

        init(
            accountOperationFactory: MetaAccountOperationFactoryProtocol,
            accountRepository: AnyDataProviderRepository<MetaAccountModel>,
            operationManager: OperationManagerProtocol,
            settings: SelectedWalletSettings,
            keystoreImportService: KeystoreImportServiceProtocol,
            eventCenter: EventCenterProtocol
        ) {
            self.settings = settings
            self.eventCenter = eventCenter

            super.init(
                accountOperationFactory: accountOperationFactory,
                accountRepository: accountRepository,
                operationManager: operationManager,
                keystoreImportService: keystoreImportService,
                supportedNetworks: Chain.allCases, // TODO: Remove after interactors are done
                defaultNetwork: Chain.kusama // TODO: Remove after interactors are done
            )
        }

        private func importAccountItem(_ item: MetaAccountModel) {
            let checkOperation = accountRepository.fetchOperation(
                by: item.identifier,
                options: RepositoryFetchOptions()
            )

            let saveOperation: ClosureOperation<MetaAccountModel> = ClosureOperation { [weak self] in
                if try checkOperation
                    .extractResultData(throwing: BaseOperationError.parentOperationCancelled) != nil {
                    throw AccountCreateError.duplicated
                }

                self?.settings.save(value: item)

                return item
            }

            let persistentOperation = accountRepository.saveOperation({
                if try checkOperation
                    .extractResultData(throwing: BaseOperationError.parentOperationCancelled) != nil {
                    throw AccountCreateError.duplicated
                }

                return [item]
            }, { [] })

            persistentOperation.addDependency(checkOperation)

//            let selectedConnection = settings.selectedConnection

//            let connectionOperation: BaseOperation<(AccountItem, ConnectionItem)> = ClosureOperation {
//                if case let .failure(error) = persistentOperation.result {
//                    throw error
//                }
//
//                let type = try SS58AddressFactory().type(fromAddress: item.address)
//
//                let resultConnection: ConnectionItem
//
//                if selectedConnection.type == SNAddressType(rawValue: type.uint8Value) {
//                    resultConnection = selectedConnection
//                } else if let connection = ConnectionItem.supportedConnections
//                    .first(where: { $0.type.rawValue == type.uint8Value }) {
//                    resultConnection = connection
//                } else {
//                    throw AccountCreateError.unsupportedNetwork
//                }
//
//                return (item, resultConnection)
//            }
//
//            connectionOperation.addDependency(persistentOperation)
//
//            connectionOperation.completionBlock = { [weak self] in
//                DispatchQueue.main.async {
//                    switch connectionOperation.result {
//                    case .success(let (accountItem, connectionItem)):
//                        self?.settings.selectedAccount = accountItem
//
//                        if selectedConnection != connectionItem {
//                            self?.settings.selectedConnection = connectionItem
//
//                            self?.eventCenter.notify(with: SelectedConnectionChanged())
//                        }
//
//                        self?.eventCenter.notify(with: SelectedAccountChanged())
//
//                        self?.presenter?.didCompleteAccountImport()
//                    case let .failure(error):
//                        self?.presenter?.didReceiveAccountImport(error: error)
//                    case .none:
//                        let error = BaseOperationError.parentOperationCancelled
//                        self?.presenter?.didReceiveAccountImport(error: error)
//                    }
//                }
//            }

            operationManager.enqueue(
                operations: [checkOperation, persistentOperation],
                in: .transient
            )
        }

        override func importAccountUsingOperation(_ importOperation: BaseOperation<MetaAccountModel>) {
            importOperation.completionBlock = { [weak self] in
                DispatchQueue.main.async {
                    switch importOperation.result {
                    case let .success(accountItem):
                        self?.importAccountItem(accountItem)
                    case let .failure(error):
                        self?.presenter?.didReceiveAccountImport(error: error)
                    case .none:
                        let error = BaseOperationError.parentOperationCancelled
                        self?.presenter?.didReceiveAccountImport(error: error)
                    }
                }
            }

            operationManager.enqueue(operations: [importOperation], in: .transient)
        }
    }
}
