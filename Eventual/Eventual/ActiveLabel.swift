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
            actionBoundingRects.removeAll()
            guard let attributedText = attributedText, attributedText.length > 0 else { return }

            let layoutManager = NSLayoutManager()
            let textStorage = NSTextStorage(attributedString: attributedText)
            let textContainer = NSTextContainer(size: bounds.size)
            textContainer.lineFragmentPadding = 0
            textContainer.lineBreakMode = lineBreakMode
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)

            var glyphRange = NSRange()
            var index = 0
            repeat {
                if let attribute = attributedText.attribute(
                    ActiveLabel.actionAttributeName, at: index, effectiveRange: &glyphRange)
                    as? String,
                    glyphRange.length > 0 {
                    actionBoundingRects[attribute] = layoutManager.boundingRect(
                        forGlyphRange: glyphRange, in: layoutManager.textContainers.first!)
                    index = glyphRange.location + glyphRange.length
                } else {
                    index += 1
                }
            } while index < attributedText.length
            print(actionBoundingRects)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(detectFragmentTap(_:)))
        )
    }

    @objc private func detectFragmentTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        for (selector, boundingRect) in actionBoundingRects {
            if boundingRect.contains(location) {
                UIApplication.shared.sendAction(Action(rawValue: selector)!, from: actionSender)
                break
            }
        }
    }

}
