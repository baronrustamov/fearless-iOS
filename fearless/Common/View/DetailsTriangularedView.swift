import UIKit
import SoraUI

class DetailsTriangularedView: BackgroundedContentControl {
    enum LayoutConstants {
        static let actionButtonSize = CGSize(width: 68, height: 24)
        static let cornerRadius: CGFloat = 3
        static let iconRadius: CGFloat = 16
        static let iconSize: CGFloat = 13
        static let labelVerticalOffset: CGFloat = 2
        static let titleVerticalOffset: CGFloat = 6
    }

    enum Layout {
        case singleTitle
        case largeIconTitleSubtitle
        case smallIconTitleSubtitle
        case smallIconTitleButton
        case largeIconTitleInfoSubtitle
        case smallIconTitleSubtitleButton
        case withoutIcon
    }

    var triangularedBackgroundView: TriangularedView? {
        backgroundView as? TriangularedView
    }

    private(set) var titleLabel: ShimmeredLabel!
    private(set) var subtitleLabel: UILabel?
    private(set) var actionButton: TriangularedButton?
    private(set) var additionalInfoView: UIButton?
    var iconView: UIImageView { lazyIconViewOrCreateIfNeeded() }
    var actionView: UIImageView { lazyActionViewOrCreateIfNeeded() }
    var actionColor: UIColor?

    private var lazyIconView: UIImageView?
    private var lazyActionView: UIImageView?

    var horizontalSpacing: CGFloat = UIConstants.defaultOffset {
        didSet {
            setNeedsLayout()
        }
    }

    func makeAdditionalInfoView() -> UIButton {
        let button = UIButton()
        button.backgroundColor = R.color.colorWhite16()
        button.setTitleColor(R.color.colorTransparentText(), for: .normal)
        button.layer.cornerRadius = LayoutConstants.cornerRadius
        button.titleLabel?.font = UIFont.capsTitle
        button.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: UIConstants.minimalOffset,
            bottom: 0,
            right: UIConstants.minimalOffset
        )
        return button
    }

    func makeActionButton() -> TriangularedButton {
        let actionButton = TriangularedButton()
        actionButton.applyEnabledStyle()
        actionButton.triangularedView?.fillColor = actionColor ?? R.color.colorPurple()!
        actionButton.imageWithTitleView?.titleFont = .h6Title
        actionButton.triangularedView?.sideLength = 4
        return actionButton
    }

    var iconRadius: CGFloat = LayoutConstants.iconRadius {
        didSet {
            setNeedsLayout()
        }
    }

    var layout: Layout = .largeIconTitleSubtitle {
        didSet {
            switch layout {
            case .largeIconTitleSubtitle, .smallIconTitleSubtitle:
                if subtitleLabel == nil {
                    let label = UILabel()
                    subtitleLabel = label
                    contentView?.addSubview(label)
                }
            case .singleTitle:
                if subtitleLabel != nil {
                    subtitleLabel?.removeFromSuperview()
                    subtitleLabel = nil
                }
            case .smallIconTitleButton:
                if subtitleLabel != nil {
                    subtitleLabel?.removeFromSuperview()
                    subtitleLabel = nil
                }
                if actionButton == nil {
                    let actionButton = makeActionButton()
                    self.actionButton = actionButton
                    contentView?.addSubview(actionButton)
                }
            case .largeIconTitleInfoSubtitle:
                if subtitleLabel == nil {
                    let label = UILabel()
                    subtitleLabel = label
                    contentView?.addSubview(label)
                }
                if additionalInfoView == nil {
                    let view = makeAdditionalInfoView()
                    additionalInfoView = view
                    contentView?.addSubview(view)
                }
            case .smallIconTitleSubtitleButton:
                if subtitleLabel == nil {
                    let label = UILabel()
                    subtitleLabel = label
                    contentView?.addSubview(label)
                }
                if actionButton == nil {
                    let actionButton = makeActionButton()
                    self.actionButton = actionButton
                    contentView?.addSubview(actionButton)
                }
            case .largeIconTitleInfoSubtitle:
                if subtitleLabel == nil {
                    let label = UILabel()
                    subtitleLabel = label
                    contentView?.addSubview(label)
                }
                if additionalInfoView == nil {
                    let view = makeAdditionalInfoView()
                    additionalInfoView = view
                    contentView?.addSubview(view)
                }
            case .withoutIcon:
                iconView.removeFromSuperview()
            }

            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView?.frame = bounds

        if let actionView = lazyActionView {
            actionView.frame = CGRect(
                x: bounds.maxX - bounds.height,
                y: bounds.minY,
                width: bounds.height,
                height: bounds.height
            )
        }

        switch layout {
        case .largeIconTitleSubtitle:
            layoutLargeIconTitleSubtitle()
        case .smallIconTitleSubtitle:
            layoutSmallIconTitleSubtitle()
        case .singleTitle:
            layoutSingleTitle()
        case .smallIconTitleButton:
            layoutSmallIconTitleButton()
        case .largeIconTitleInfoSubtitle:
            layoutLargeIconTitleInfoSubtitle()
        case .smallIconTitleSubtitleButton:
            layoutSmallIconTitleSubtitleButton()
        case .withoutIcon:
            layoutWithoutIcon()
        }
    }

    private func layoutSmallIconTitleSubtitleButton() {
        guard let subtitleLabel = subtitleLabel else {
            return
        }

        let titleHeight = titleLabel.intrinsicContentSize.height
        let titleWidth = titleLabel.intrinsicContentSize.width
        let subtitleHeight = subtitleLabel.intrinsicContentSize.height
        let subtitleWidth = subtitleLabel.intrinsicContentSize.width

        let iconOffset = lazyIconView != nil ? LayoutConstants.iconSize + horizontalSpacing : 0.0
        let labelX = bounds.minX + contentInsets.left + iconOffset

        if let actionButton = actionButton {
            actionButton.frame = CGRect(
                x: bounds.maxX - contentInsets.right - LayoutConstants.actionButtonSize.width,
                y: bounds.midY - LayoutConstants.actionButtonSize.height / 2,
                width: LayoutConstants.actionButtonSize.width,
                height: LayoutConstants.actionButtonSize.height
            )
        }

        titleLabel.frame = CGRect(
            x: labelX,
            y: UIConstants.defaultOffset,
            width: titleWidth,
            height: titleHeight
        )

        subtitleLabel.frame = CGRect(
            x: labelX,
            y: bounds.size.height / 2 + LayoutConstants.labelVerticalOffset,
            width: subtitleWidth,
            height: subtitleHeight
        )

        if let iconView = lazyIconView {
            iconView.frame = CGRect(
                x: bounds.minX + contentInsets.left,
                y: UIConstants.defaultOffset,
                width: LayoutConstants.iconSize,
                height: LayoutConstants.iconSize
            )
        }
    }

    private func layoutWithoutIcon() {
        let titleHeight = titleLabel.intrinsicContentSize.height
        let labelX = bounds.minX + contentInsets.left

        let trailing = lazyActionView?.frame.minX ?? bounds.maxX - contentInsets.right
        titleLabel.frame = CGRect(
            x: labelX,
            y: bounds.minY + contentInsets.top,
            width: trailing - labelX,
            height: titleHeight
        )

        let subtitleHeight = subtitleLabel?.intrinsicContentSize.height ?? 0.0
        subtitleLabel?.frame = CGRect(
            x: labelX,
            y: bounds.maxY - contentInsets.bottom - subtitleHeight,
            width: trailing - labelX,
            height: subtitleHeight
        )
    }

    private func layoutLargeIconTitleInfoSubtitle() {
        let titleHeight = titleLabel.intrinsicContentSize.height
        let titleWidth = titleLabel.intrinsicContentSize.width

        let iconOffset = lazyIconView != nil ? 2.0 * iconRadius + horizontalSpacing : 0.0
        let labelX = bounds.minX + contentInsets.left + iconOffset

        let trailing = lazyActionView?.frame.minX ?? bounds.maxX - contentInsets.right
        titleLabel.frame = CGRect(
            x: labelX,
            y: bounds.minY + contentInsets.top,
            width: titleWidth,
            height: titleHeight
        )

        let subtitleHeight = subtitleLabel?.intrinsicContentSize.height ?? 0.0
        subtitleLabel?.frame = CGRect(
            x: labelX,
            y: bounds.maxY - contentInsets.bottom - subtitleHeight,
            width: trailing - labelX,
            height: subtitleHeight
        )

        if let iconView = lazyIconView {
            iconView.frame = CGRect(
                x: bounds.minX + contentInsets.left,
                y: bounds.midY - iconRadius,
                width: 2.0 * iconRadius,
                height: 2.0 * iconRadius
            )
        }

        let titleInsets: UIEdgeInsets = additionalInfoView?.titleEdgeInsets ?? .zero
        let additionalWidth = (additionalInfoView?.intrinsicContentSize.width ?? 0.0) + titleInsets.left + titleInsets.right
        additionalInfoView?.frame = CGRect(
            x: titleLabel.frame.origin.x + titleLabel.frame.size.width + UIConstants.defaultOffset,
            y: bounds.minY + contentInsets.top,
            width: additionalWidth,
            height: titleHeight
        )
    }

    private func layoutSmallIconTitleButton() {
        let titleHeight = bounds.height - LayoutConstants.titleVerticalOffset * 2

        let iconOffset = lazyIconView != nil ? 2.0 * iconRadius + horizontalSpacing : 0.0
        let labelX = bounds.minX + contentInsets.left + iconOffset

        if let actionButton = actionButton {
            actionButton.frame = CGRect(
                x: bounds.maxX - contentInsets.right - LayoutConstants.actionButtonSize.width,
                y: bounds.midY - LayoutConstants.actionButtonSize.height / 2,
                width: LayoutConstants.actionButtonSize.width,
                height: LayoutConstants.actionButtonSize.height
            )
        }

        let trailing = actionButton?.frame.minX ?? bounds.maxX - contentInsets.right

        titleLabel.frame = CGRect(
            x: labelX,
            y: bounds.midY - LayoutConstants.titleVerticalOffset,
            width: trailing - labelX,
            height: titleHeight
        )

        let subtitleHeight = subtitleLabel?.intrinsicContentSize.height ?? 0.0
        subtitleLabel?.frame = CGRect(
            x: labelX,
            y: titleLabel.frame.maxY + LayoutConstants.labelVerticalOffset,
            width: trailing - labelX,
            height: subtitleHeight
        )

        if let iconView = lazyIconView {
            iconView.frame = CGRect(
                x: bounds.minX + contentInsets.left,
                y: bounds.midY - iconRadius,
                width: 2.0 * iconRadius,
                height: 2.0 * iconRadius
            )
        }
    }

    private func layoutLargeIconTitleSubtitle() {
        let titleHeight = titleLabel.intrinsicContentSize.height

        let iconOffset = lazyIconView != nil ? 2.0 * iconRadius + horizontalSpacing : 0.0
        let labelX = bounds.minX + contentInsets.left + iconOffset

        let trailing = lazyActionView?.frame.minX ?? bounds.maxX - contentInsets.right
        titleLabel.frame = CGRect(
            x: labelX,
            y: bounds.minY + contentInsets.top,
            width: trailing - labelX,
            height: titleHeight
        )

        let subtitleHeight = subtitleLabel?.intrinsicContentSize.height ?? 0.0
        subtitleLabel?.frame = CGRect(
            x: labelX,
            y: bounds.maxY - contentInsets.bottom - subtitleHeight,
            width: trailing - labelX,
            height: subtitleHeight
        )

        if let iconView = lazyIconView {
            iconView.frame = CGRect(
                x: bounds.minX + contentInsets.left,
                y: bounds.midY - iconRadius,
                width: 2.0 * iconRadius,
                height: 2.0 * iconRadius
            )
        }
    }

    private func layoutSmallIconTitleSubtitle() {
        let titleHeight = titleLabel.intrinsicContentSize.height
        let titleX = bounds.minX + contentInsets.left

        let trailing = lazyActionView?.frame.minX ?? bounds.maxX - contentInsets.right
        titleLabel.frame = CGRect(
            x: titleX,
            y: bounds.minY + contentInsets.top,
            width: trailing - titleX,
            height: titleHeight
        )

        let subtitleHeight = subtitleLabel?.intrinsicContentSize.height ?? 0.0
        let subtitleX = lazyIconView != nil ? titleX + 2.0 * iconRadius + horizontalSpacing : titleX
        subtitleLabel?.frame = CGRect(
            x: subtitleX,
            y: bounds.maxY - contentInsets.bottom - subtitleHeight,
            width: trailing - subtitleX,
            height: subtitleHeight
        )

        if let iconView = lazyIconView {
            let subtitleCenter = subtitleLabel?.frame.midY ?? bounds.midY
            iconView.frame = CGRect(
                x: titleX,
                y: subtitleCenter - iconRadius,
                width: 2.0 * iconRadius,
                height: 2.0 * iconRadius
            )
        }
    }

    private func layoutSingleTitle() {
        let titleHeight = bounds.height - UIConstants.bigOffset

        let iconOffset = lazyIconView != nil ? 2.0 * iconRadius + horizontalSpacing : 0.0
        let labelX = bounds.minX + contentInsets.left + iconOffset
        let trailing = lazyActionView?.frame.minX ?? bounds.maxX - contentInsets.right

        titleLabel.frame = CGRect(
            x: labelX,
            y: bounds.midY - titleHeight / 2.0,
            width: trailing - labelX,
            height: titleHeight
        )

        if let iconView = lazyIconView {
            iconView.frame = CGRect(
                x: bounds.minX + contentInsets.left,
                y: bounds.midY - iconRadius,
                width: 2.0 * iconRadius,
                height: 2.0 * iconRadius
            )
        }
    }

    private func configure() {
        backgroundColor = UIColor.clear

        configureBackgroundViewIfNeeded()
        configureContentViewIfNeeded()
    }

    private func configureBackgroundViewIfNeeded() {
        if backgroundView == nil {
            let triangularedView = TriangularedView()
            triangularedView.isUserInteractionEnabled = false
            triangularedView.shadowOpacity = 0.0

            backgroundView = triangularedView
        }
    }

    private func lazyActionViewOrCreateIfNeeded() -> UIImageView {
        if let actionButton = lazyActionView {
            return actionButton
        }

        let imageView = UIImageView()
        imageView.contentMode = .center
        contentView?.addSubview(imageView)

        lazyActionView = imageView

        if superview != nil {
            setNeedsLayout()
        }

        return imageView
    }

    private func lazyIconViewOrCreateIfNeeded() -> UIImageView {
        if let iconView = lazyIconView {
            return iconView
        }

        let imageView = UIImageView()
        contentView?.addSubview(imageView)

        lazyIconView = imageView

        if superview != nil {
            setNeedsLayout()
        }

        return imageView
    }

    private func configureContentViewIfNeeded() {
        if contentView == nil {
            let contentView = UIView()
            contentView.backgroundColor = .clear
            contentView.isUserInteractionEnabled = false
            self.contentView = contentView
        }

        if titleLabel == nil {
            titleLabel = ShimmeredLabel()
            contentView?.addSubview(titleLabel)
        }

        if subtitleLabel == nil, layout != .singleTitle {
            let label = UILabel()
            contentView?.addSubview(label)
            subtitleLabel = label
        }
    }
}
