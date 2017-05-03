//
//  ActiveLabel.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class ActiveLabel: UILabel {

    static let actionAttributeName = "ActiveLabelAction"

    weak var actionSender: NSObjectProtocol?

    private var actionBoundingRects = [String : CGRect]()

    override var attributedText: NSAttributedString? {
        didSet {
            guard isUserInteractionEnabled else { return }
            updateActionBoundingRects()
        }
    }

    private weak var actionTapRecognizer: UITapGestureRecognizer?

    override var isUserInteractionEnabled: Bool {
        didSet {
            guard isUserInteractionEnabled && actionTapRecognizer == nil else { return }
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(detectFragmentTap(_:)))
            addGestureRecognizer(tapRecognizer)
            actionTapRecognizer = tapRecognizer
        }
    }

    private func updateActionBoundingRects() {
        actionBoundingRects.removeAll()
        guard let attributedText = attributedText, attributedText.length > 0 else { return }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        var glyphRange = NSRange()
        var index = 0
        repeat {
            let actionAttribute = attributedText.attribute(
                ActiveLabel.actionAttributeName, at: index, effectiveRange: &glyphRange
            ) as? String
            if let actionAttribute = actionAttribute {
                var boundingRect = layoutManager.boundingRect(
                    forGlyphRange: glyphRange, in: layoutManager.textContainers.first!
                )
                boundingRect.origin.y = bounds.origin.y
                boundingRect.size.height = bounds.size.height
                actionBoundingRects[actionAttribute] = boundingRect
                index = glyphRange.location + glyphRange.length
            } else {
                index += 1
            }
        } while index < attributedText.length
        // print(actionBoundingRects)
    }

    @objc private func detectFragmentTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        for (selector, boundingRect) in actionBoundingRects {
            guard boundingRect.contains(location) else { continue }
            UIApplication.shared.sendAction(Action(rawValue: selector)!, from: actionSender)
            break
        }
    }

}
