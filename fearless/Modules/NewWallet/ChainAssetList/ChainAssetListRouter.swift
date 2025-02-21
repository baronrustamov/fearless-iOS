import Foundation

final class ChainAssetListRouter: ChainAssetListRouterInput {
    func showChainAccount(
        from view: ControllerBackedProtocol?,
        chainAsset: ChainAsset
    ) {
        guard let chainAssetView = WalletChainAccountDashboardViewFactory.createView(
            chainAsset: chainAsset
        ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            chainAssetView.controller,
            animated: true
        )
    }

    func showSendFlow(
        from view: ControllerBackedProtocol?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel
    ) {
        guard let controller = SendAssembly.configureModule(
            wallet: wallet,
            initialData: .chainAsset(chainAsset)
        )?.view.controller else {
            return
        }

        let navigationController = FearlessNavigationController(rootViewController: controller)
        view?.controller.present(navigationController, animated: true)
    }

    func showReceiveFlow(
        from view: ControllerBackedProtocol?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel
    ) {
        let receiveView = ReceiveAssetViewFactory.createView(
            account: wallet,
            chain: chainAsset.chain,
            asset: chainAsset.asset
        )

        guard let controller = receiveView?.controller else {
            return
        }

        view?.controller.present(controller, animated: true)
    }

    func presentAccountOptions(
        from view: ControllerBackedProtocol?,
        locale: Locale?,
        actions: [SheetAlertPresentableAction]
    ) {
        let cancelTitle = R.string.localizable
            .commonCancel(preferredLanguages: locale?.rLanguages)

        let title = R.string.localizable.importSourcePickerTitle(preferredLanguages: locale?.rLanguages)
        let alertViewModel = SheetAlertPresentableViewModel(
            title: title,
            message: nil,
            actions: actions,
            closeAction: cancelTitle
        )

        present(
            viewModel: alertViewModel,
            from: view
        )
    }

    func showCreate(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?) {
        guard let controller = UsernameSetupViewFactory.createViewForOnboarding(
            flow: .chain(model: uniqueChainModel)
        )?.controller else {
            return
        }

        let navigationController = FearlessNavigationController(
            rootViewController: controller
        )

        view?.controller.present(navigationController, animated: true)
    }

    func showImport(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?) {
        guard let importController = AccountImportViewFactory.createViewForOnboarding(
            .chain(model: uniqueChainModel)
        )?.controller else {
            return
        }

        let navigationController = FearlessNavigationController(
            rootViewController: importController
        )

        view?.controller.present(navigationController, animated: true)
    }
}
