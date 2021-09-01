import UIKit
import Charts

final class FWBarChartView: BarChartView {
    weak var chartDelegate: FWChartViewDelegate?

    let xAxisEmptyFormatter = FWXAxisEmptyValueFormatter()
    let xAxisLegend = FWXAxisChartLegendView()
    let yAxisFormatter = FWYAxisChartFormatter()

    private let averageAmountLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.colorGreen()
        label.font = .systemFont(ofSize: 9, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()

    private var averageLabelHeightPercent: Double?
    private let averageLineLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = R.color.colorGreen()!.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [3, 3]
        shapeLayer.lineWidth = 0.5
        return shapeLayer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        delegate = self
        backgroundColor = .clear
        chartDescription?.enabled = false

        autoScaleMinMaxEnabled = true
        doubleTapToZoomEnabled = false
        drawBarShadowEnabled = false
        drawValueAboveBarEnabled = false
        highlightFullBarEnabled = false
        pinchZoomEnabled = false
        dragYEnabled = false

        xAxis.drawGridLinesEnabled = false
        xAxis.labelPosition = .bottom
        xAxis.valueFormatter = xAxisEmptyFormatter

        leftAxis.labelCount = 1
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawAxisLineEnabled = false
        leftAxis.valueFormatter = yAxisFormatter
        leftAxis.labelFont = .systemFont(ofSize: 9, weight: .semibold)
        leftAxis.labelTextColor = UIColor.white.withAlphaComponent(0.64)
        leftAxis.axisMinimum = 0

        rightAxis.enabled = false
        drawBordersEnabled = false
        minOffset = 0
        legend.enabled = false

        noDataText = ""

        addSubview(xAxisLegend)
        xAxisLegend.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(40)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        addSubview(averageAmountLabel)
        layer.insertSublayer(averageLineLayer, at: 0)
        // layer.addSublayer(averageLineLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let percent = averageLabelHeightPercent, percent > .leastNonzeroMagnitude else {
            averageAmountLabel.isHidden = true
            averageLineLayer.isHidden = true
            return
        }

        let yPosition = CGFloat(percent) * (bounds.height - xAxisLegend.bounds.height - 5)
        averageAmountLabel.frame = CGRect(
            origin: CGPoint(x: 0, y: yPosition),
            size: CGSize(width: 44, height: 22)
        )
        averageAmountLabel.isHidden = false

        averageLineLayer.isHidden = false
        let path = CGMutablePath()
        path.move(to: CGPoint(x: averageAmountLabel.frame.maxX, y: yPosition))
        path.addLine(to: CGPoint(x: bounds.maxX, y: yPosition))
        averageLineLayer.path = path
    }
}

extension FWBarChartView: FWChartViewProtocol {
    func setChartData(_ data: ChartData, animated: Bool) {
        let dataEntries = data.amounts.enumerated().map { index, amount in
            BarChartDataEntry(x: Double(index), yValues: [amount.value])
        }

        let realAmounts = data.amounts.map { chartAmount -> Double in
            if !chartAmount.filled {
                return 0.0
            }
            return chartAmount.value
        }
        let (min, max) = (realAmounts.min() ?? 0.0, realAmounts.max() ?? 0.0)
        averageLabelHeightPercent = (data.averageAmountValue - min) / (max - min)
        averageAmountLabel.text = data.averageAmountText
        setNeedsLayout()

        let set = BarChartDataSet(entries: dataEntries)
        set.highlightColor = R.color.colorAccent()!
        set.drawIconsEnabled = false
        set.drawValuesEnabled = false
        let chartDataContainsSelectedBar = data.amounts.contains(where: { $0.selected == true })
        set.colors = data.amounts.map { chartData in
            if chartData.selected {
                return R.color.colorAccent()!
            } else {
                if chartDataContainsSelectedBar {
                    return UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
                } else {
                    return chartData.filled ? R.color.colorAccent()! : R.color.colorGray()!
                }
            }
        }

        xAxisLegend.setValues(data.xAxisValues)
        yAxisFormatter.bottomValueString = data.bottomYValue

        let data = BarChartData(dataSet: set)
        data.barWidth = 0.4

        self.data = data
        if animated {
            animate(yAxisDuration: 0.3, easingOption: .easeInOutCubic)
        }
    }
}

extension FWBarChartView: ChartViewDelegate {
    func chartValueSelected(_: ChartViewBase, entry: ChartDataEntry, highlight _: Highlight) {
        chartDelegate?.didSelectXValue(entry.x)
    }

    func chartValueNothingSelected(_: ChartViewBase) {
        chartDelegate?.didUnselect()
    }
}
