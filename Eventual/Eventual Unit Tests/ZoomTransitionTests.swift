//
//  ZoomTransitionTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class ZoomTransitionTests: XCTestCase {

    class TestTransitionDelegate: NSObject, TransitionAnimationDelegate {

        func animatedTransition(_ transition: AnimatedTransition, snapshotReferenceViewWhenReversed reversed: Bool) -> UIView {
            return UIView(frame: .zero)
        }

    }

    var transition: ZoomTransition!

    override func setUp() {
        super.setUp()
        transition = ZoomTransition(delegate: TestTransitionDelegate())
        transition.zoomedOutReferenceViewBorderWidth = 0
    }

    func testAspectFittingZoomedOutFrameOfZoomedInSize() {
        transition.zoomedInFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        transition.zoomedOutFrame = CGRect(x: 0, y: 50, width: 100, height: 100)
        let frame = transition.aspectFittingZoomedOutFrameOfZoomedInSize
        XCTAssertEqual(frame.size, CGSize(width: 480, height: 480))
    }

    func testAspectFittingZoomedInFrameOfZoomedOutSize() {
        transition.zoomedOutFrame = CGRect(x: 0, y: 50, width: 100, height: 100)
        transition.zoomedInFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let frame = transition.aspectFittingZoomedInFrameOfZoomedOutSize
        XCTAssertEqual(frame.size, CGSize(width: 100 * 2 / 3.0, height: 100))
    }

}
