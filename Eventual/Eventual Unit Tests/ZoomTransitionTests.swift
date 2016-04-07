//
//  ZoomTransitionTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class ZoomTransitionTests: XCTestCase {

    class TestTransitionDelegate: NSObject, TransitionAnimationDelegate {
        func animatedTransition(transition: AnimatedTransition, snapshotReferenceViewWhenReversed reversed: Bool) -> UIView {
            return UIView(frame: CGRectZero)
        }
    }

    var transition: ZoomTransition!
    override func setUp() {
        super.setUp()
        self.transition = ZoomTransition(delegate: TestTransitionDelegate())
        self.transition.zoomedOutReferenceViewBorderWidth = 0
    }

    func testAspectFittingZoomedOutFrameOfZoomedInSize() {
        self.transition.zoomedInFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        self.transition.zoomedOutFrame = CGRect(x: 0, y: 50, width: 100, height: 100)
        let frame = self.transition.aspectFittingZoomedOutFrameOfZoomedInSize
        XCTAssertEqual(frame.size, CGSize(width: 480, height: 480))
    }

    func testAspectFittingZoomedInFrameOfZoomedOutSize() {
        self.transition.zoomedOutFrame = CGRect(x: 0, y: 50, width: 100, height: 100)
        self.transition.zoomedInFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let frame = self.transition.aspectFittingZoomedInFrameOfZoomedOutSize
        XCTAssertEqual(frame.size, CGSize(width: 100 * 2 / 3.0, height: 100))
    }
}
