import Foundation
import IrohaCrypto

extension AddAccount {
    final class AccountImportWireframe: AccountImportWireframeProtocol {
        func showSecondStep(from view: AccountImportViewProtocol?, with data: AccountCreationStep.FirstStepData) {
            guard let secondStep = AccountImportViewFactory.createViewForAdding(.wallet(step: .second(data: data))) else {
                return
            }

            if let navigationController = view?.controller.navigationController {
                navigationController.pushViewController(secondStep.controller, animated: true)
            }
        }

        func proceed(from view: AccountImportViewProtocol?, flow _: AccountImportFlow) {
            guard let navigationController = view?.controller.navigationController else {
                return
            }
            MainTransitionHelper.transitToMainTabBarController(
                closing: navigationController,
                animated: true
            )
        }

        func presentSourceTypeSelection(
            from view: AccountImportViewProtocol?,
            availableSources: [AccountImportSource],
            selectedSource: AccountImportSource,
            delegate: ModalPickerViewControllerDelegate?,
            context: AnyObject?
        ) {
            guard let modalPicker = ModalPickerFactory.createPickerForList(
                availableSources,
                selectedType: selectedSource,
                delegate: delegate,
                context: context
            ) else {
                return
            }

            view?.controller.navigationController?.present(
                modalPicker,
                animated: true,
                completion: nil
            )
        }

        func presentCryptoTypeSelection(
            from view: AccountImportViewProtocol?,
            availableTypes: [CryptoType],
            selectedType: CryptoType,
            delegate: ModalPickerViewControllerDelegate?,
            context: AnyObject?
        ) {
            guard let modalPicker = ModalPickerFactory.createPickerForList(
                availableTypes,
                selectedType: selectedType,
                delegate: delegate,
                context: context
            ) else {
                return
            }

            view?.controller.navigationController?.present(
                modalPicker,
                animated: true,
                completion: nil
            )
        }

        func presentNetworkTypeSelection(
            from view: AccountImportViewProtocol?,
            availableTypes: [Chain],
            selectedType: Chain,
            delegate: ModalPickerViewControllerDelegate?,
            context: AnyObject?
        ) {
            guard let modalPicker = ModalPickerFactory.createPickerForList(
                availableTypes,
                selectedType: selectedType,
                delegate: delegate,
                context: context
            ) else {
                return
            }

            view?.controller.navigationController?.present(
                modalPicker,
                animated: true,
                completion: nil
            )
        }
    }
}
