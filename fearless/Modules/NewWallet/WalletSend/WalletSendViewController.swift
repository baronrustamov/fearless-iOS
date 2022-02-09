import UIKit
import CommonWallet
import SoraFoundation

final class WalletSendViewController: UIViewController, ViewHolder {
    typealias RootViewType = WalletSendViewLayout

    let presenter: WalletSendPresenterProtocol

    private var state: WalletSendViewState = .loading

    init(presenter: WalletSendPresenterProtocol, localizationManager: LocalizationManagerProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = WalletSendViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBalanceAccessoryView()
        setupAmountInputView()
        setupLocalization()
        presenter.setup()

        rootView.navigationBar.backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
    }

    private func setupLocalization() {
        rootView.locale = selectedLocale
    }

    private func setupAmountInputView() {
        rootView.amountView.textField.delegate = self

        rootView.actionButton.addTarget(self, action: #selector(continueButtonClicked), for: .touchUpInside)
    }

    private func setupBalanceAccessoryView() {
        let locale = localizationManager?.selectedLocale ?? Locale.current
        let accessoryView = UIFactory.default.createAmountAccessoryView(for: self, locale: locale)
        rootView.amountView.textField.inputAccessoryView = accessoryView
    }

    private func applyState(_ state: WalletSendViewState) {
        switch state {
        case .loading:
            break
        case let .loaded(walletSendViewModel):
            if let accountViewModel = walletSendViewModel.accountViewModel {
                rootView.bind(accountViewModel: accountViewModel)
            }

            rootView.bind(feeViewModel: walletSendViewModel.feeViewModel)

            if let assetViewModel = walletSendViewModel.assetBalanceViewModel {
                rootView.bind(assetViewModel: assetViewModel)
            }

            if let amountViewModel = walletSendViewModel.amountInputViewModel {
                amountViewModel.observable.remove(observer: self)
                amountViewModel.observable.add(observer: self)
                rootView.amountView.fieldText = amountViewModel.displayAmount
                updateActionButton()
            }
        }
    }

    private func updateActionButton() {
        guard case let .loaded(viewModel) = state else {
            return
        }
        let isEnabled = (viewModel.amountInputViewModel?.isValid == true)
        rootView.actionButton.set(enabled: isEnabled)
    }

    @objc private func continueButtonClicked() {
        presenter.didTapContinueButton()
    }

    @objc private func backButtonClicked() {
        presenter.didTapBackButton()
    }
}

extension WalletSendViewController: WalletSendViewProtocol {
    func didReceive(title: String) {
        rootView.navigationTitleLabel.text = title
    }

    func didReceive(state: WalletSendViewState) {
        self.state = state

        applyState(state)
    }
}

extension WalletSendViewController: HiddableBarWhenPushed {}

extension WalletSendViewController: UITextFieldDelegate {
    func textField(
        _: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard case let .loaded(viewModel) = state else {
            return false
        }

        return viewModel.amountInputViewModel?.didReceiveReplacement(string, for: range) ?? false
    }
}

extension WalletSendViewController: AmountInputAccessoryViewDelegate {
    func didSelect(on _: AmountInputAccessoryView, percentage: Float) {
        rootView.amountView.textField.resignFirstResponder()

        presenter.selectAmountPercentage(percentage)
    }

    func didSelectDone(on _: AmountInputAccessoryView) {
        rootView.amountView.textField.resignFirstResponder()
    }
}

extension WalletSendViewController: AmountInputViewModelObserver {
    func amountInputDidChange() {
        guard case let .loaded(viewModel) = state else {
            return
        }
        rootView.amountView.fieldText = viewModel.amountInputViewModel?.displayAmount

        updateActionButton()

        let amount = viewModel.amountInputViewModel?.decimalAmount ?? 0.0
        presenter.updateAmount(amount)
    }
}

extension WalletSendViewController: Localizable {
    func applyLocalization() {}
}
