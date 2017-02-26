//
//  MonthTilesView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class MonthTilesView: UIView {

    @IBOutlet private(set) var heightConstraint: NSLayoutConstraint?

    var numberOfDays = 0 {
        didSet {
            let height = tileSize * CGFloat(numberOfRows)
            guard !shouldSupportAnimation else {
                frame.size.height = height
                return
            }
            heightConstraint!.constant = height
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    var numberOfColumns = 2
    var numberOfRows: Int {
        return Int(ceil(Double(numberOfDays) / Double(numberOfColumns)))
    }
    var lineWidth: CGFloat = 1
    var tileSize: CGFloat {
        return frame.width / CGFloat(numberOfColumns)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        guard !shouldSupportAnimation else { return }
        let context = UIGraphicsGetCurrentContext()!
        let r = rect.insetBy(dx: lineWidth, dy: lineWidth)

        context.setFillColor(UIColor.white.cgColor)
        context.setLineWidth(lineWidth)
        context.setStrokeColor(Appearance.blueColor.cgColor)

        context.fill(r)
        context.stroke(r)

        for i in 1..<numberOfColumns {
            let x = tileSize * CGFloat(i)
            context.addLines(between: [CGPoint(x: x, y: r.minY), CGPoint(x: x, y: r.maxY)])
        }
        for i in 1..<numberOfRows {
            let y = tileSize * CGFloat(i)
            context.addLines(between: [CGPoint(x: r.minX, y: y), CGPoint(x: r.maxX, y: y)])
        }
        context.strokePath()

        if numberOfDays % 2 == 1 {
            let maskSize = tileSize - lineWidth / 2
            context.clear(CGRect(
                origin: CGPoint(x: rect.maxX - maskSize, y: rect.maxY - maskSize),
                size: CGSize(width: maskSize, height: maskSize)
            ))
        }
    }

    private var shouldSupportAnimation = false

    convenience init(reference: MonthTilesView) {
        self.init(frame: reference.convert(reference.frame, to: nil))
        backgroundColor = reference.backgroundColor
        isOpaque = reference.isOpaque
        numberOfDays = reference.numberOfDays
        shouldSupportAnimation = true
        addSubviews()
    }

    private func addSubviews() {
        guard shouldSupportAnimation else { preconditionFailure() }
        translatesAutoresizingMaskIntoConstraints = false
        for _ in 0..<numberOfDays {
            let tile = UIView(frame: .zero)
            tile.layer.backgroundColor = UIColor.white.cgColor
            tile.layer.borderColor = Appearance.blueColor.cgColor
            tile.layer.borderWidth = lineWidth
            addSubview(tile)
        }
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard shouldSupportAnimation else { return }
        for (i, tile) in subviews.enumerated() {
            tile.frame = CGRect(x: tileSize * CGFloat(i % numberOfColumns),
                                y: tileSize * CGFloat(i / numberOfColumns),
                                width: tileSize + lineWidth, height: tileSize + lineWidth)
        }
    }

}
