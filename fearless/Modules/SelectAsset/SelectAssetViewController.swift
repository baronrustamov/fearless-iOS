import UIKit
import SoraFoundation

final class SelectAssetViewController: SelectableListViewController<SelectAssetCell> {
    private enum Constants {
        static let cellHeight: CGFloat = 50.0
    }

    // MARK: Private properties

    private let output: SelectAssetViewOutput

    // MARK: - Constructor

    init(
        output: SelectAssetViewOutput,
        localizationManager: LocalizationManagerProtocol?
    ) {
        self.output = output
        super.init(listPresenter: output)
        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        output.didLoad(view: self)
        setupTableView()
        setupLayout()
        configure()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        output.willDisappear()
    }

    // MARK: - Private methods

    private func setupTableView() {
        rootView.tableView.rowHeight = Constants.cellHeight
        rootView.tableView.backgroundColor = .clear
        rootView.tableView.separatorStyle = .none
    }

    private func setupLayout() {
        rootView.tableView.snp.makeConstraints { make in
            make.height.equalTo(UIScreen.main.bounds.height / 2.5)
        }
    }

    private func configure() {
        rootView.backgroundColor = R.color.colorAlmostBlack()
        rootView.titleLabel.text = R.string.localizable
            .commonSelectAsset(preferredLanguages: selectedLocale.rLanguages)
    }
}

// MARK: - SelectNetworkViewInput

extension SelectAssetViewController: SelectAssetViewInput {}

// MARK: - Localizable

extension SelectAssetViewController: Localizable {
    func applyLocalization() {
        rootView.locale = selectedLocale
    }
}
