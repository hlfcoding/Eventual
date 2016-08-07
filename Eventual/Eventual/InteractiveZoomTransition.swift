//
//  InteractiveZoomTransition.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class InteractiveZoomTransition: UIPercentDrivenInteractiveTransition, InteractiveTransition, UIGestureRecognizerDelegate {

    private weak var delegate: TransitionInteractionDelegate?
    private weak var reverseDelegate: TransitionInteractionDelegate?

    var minVelocityThreshold =   (zoomIn: CGFloat(0.5), zoomOut: CGFloat(0.1))
    var maxCompletionThreshold = (zoomIn: CGFloat(0.5), zoomOut: CGFloat(0.3))
    var minScaleDeltaThreshold = (zoomIn: CGFloat(1.0), zoomOut: CGFloat(0.2))
    var minOutDestinationSpanThreshold: CGFloat = 10

    var isReversed: Bool = false

    private var pinchRecognizer: UIPinchGestureRecognizer! {
        didSet {
            pinchRecognizer.delegate = self
        }
    }
    var pinchWindow: UIWindow!

    var pinchSpan: CGFloat {
        let firstLocation = pinchRecognizer.locationOfTouch(0, inView: pinchWindow)
        let secondLocation = pinchRecognizer.locationOfTouch(1, inView: pinchWindow)
        let xSpan = fabs(firstLocation.x - secondLocation.x)
        let ySpan = fabs(firstLocation.y - secondLocation.y)
        return fmax(xSpan, ySpan)
    }
    private var sourceScale: CGFloat?
    private var destinationScale: CGFloat?
    private var isTransitioning = false

    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                pinchWindow.addGestureRecognizer(pinchRecognizer)
            } else {
                pinchWindow.removeGestureRecognizer(pinchRecognizer)
            }
        }
    }

    init(delegate: TransitionInteractionDelegate,
         reverseDelegate: TransitionInteractionDelegate? = nil) {
        super.init()

        self.delegate = delegate
        self.reverseDelegate = reverseDelegate

        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
    }

    @objc @IBAction private func handlePinch(sender: UIPinchGestureRecognizer) {
        var computedProgress: CGFloat?
        let scale = sender.scale, state = sender.state, velocity = sender.velocity
        func tearDown() {
            isReversed = false
            isTransitioning = false
            sourceScale = nil
            destinationScale = nil
        }
        print("DEBUG: state: \(state.rawValue), scale: \(scale), velocity: \(velocity)")
        switch state {
        case .Began:
            let isReversed = velocity < 0
            guard testAndBeginInTransitionForScale(scale) ||
                (isReversed && testAndBeginOutTransitionForScale(scale))
                else { break }

            self.isReversed = isReversed
            isTransitioning = true
            sourceScale = scale

        case .Changed:
            guard let destinationScale = destinationScale else { break }
            // TODO: Factor in velocity.
            var percentComplete: CGFloat!
            if isReversed {
                percentComplete = destinationScale / scale
            } else {
                percentComplete = scale / destinationScale
            }
            percentComplete = fmax(0, fmin(1, percentComplete))
            print("DEBUG: percent: \(percentComplete)")
            updateInteractiveTransition(percentComplete)

        case .Ended:
            var isCancelled: Bool
            if isReversed {
                isCancelled = fabs(velocity) < minVelocityThreshold.zoomOut &&
                    percentComplete < maxCompletionThreshold.zoomOut
            } else {
                isCancelled = fabs(velocity) < minVelocityThreshold.zoomIn &&
                    percentComplete < maxCompletionThreshold.zoomIn
            }
            if !isCancelled, let sourceScale = sourceScale {
                let delta = fabs(scale - sourceScale)
                isCancelled = delta < minScaleDeltaThreshold.zoomIn
                if isReversed {
                    isCancelled = delta < minScaleDeltaThreshold.zoomOut
                }
                print("DEBUG: delta: \(delta)")
            }
            if isCancelled {
                print("CANCELLED")
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
            }
            tearDown()

        case .Cancelled:
            self.cancelInteractiveTransition()
            tearDown()

        case .Failed:
            print("FAILED: percent: \(self.percentComplete)")
            tearDown()

        case .Possible:
            fatalError()
        }
    }

    private func testAndBeginInTransitionForScale(scale: CGFloat) -> Bool {
        guard let delegate = delegate else { return false }

        let contextView = delegate.interactiveTransition(self, locationContextViewForGestureRecognizer: pinchRecognizer)
        let location = pinchRecognizer.locationInView(contextView)
        guard
            let referenceView = delegate.interactiveTransition(
                self, snapshotReferenceViewAtLocation: location, ofContextView: contextView
            )
            else { return false }

        destinationScale = delegate.interactiveTransition( self,
            destinationScaleForSnapshotReferenceView: referenceView,
            contextView: contextView, reversed: false
        )
        if destinationScale < 0 || destinationScale == nil {
            destinationScale = contextView.frame.width / referenceView.frame.width
        }
        let destinationAmp = referenceView.frame.width / pinchSpan
        guard let destinationScale = destinationScale else { return false }

        self.destinationScale = destinationScale * destinationAmp
        print("DEBUG: reference: \(referenceView), destination: \(destinationScale)")
        delegate.beginInteractivePresentationTransition(self, withSnapshotReferenceView: referenceView)
        return true
    }

    private func testAndBeginOutTransitionForScale(scale: CGFloat) -> Bool {
        guard
            let delegate = delegate
            where delegate.respondsToSelector("beginInteractiveDismissalTransition:withSnapshotReferenceView:"),
            let reverseDelegate = reverseDelegate
            else { return false }

        let contextView = delegate.interactiveTransition(self, locationContextViewForGestureRecognizer: pinchRecognizer)
        if delegate is UIViewController {
            destinationScale = reverseDelegate.interactiveTransition( self,
                destinationScaleForSnapshotReferenceView: nil,
                contextView: contextView, reversed: true
            )
        }
        if destinationScale == nil || destinationScale < 0 {
            destinationScale = minOutDestinationSpanThreshold / (pinchSpan * (1 / scale))
        }
        print("DEBUG: destination: \(destinationScale)")
        delegate.beginInteractiveDismissalTransition(self, withSnapshotReferenceView:nil)
        return true
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer.view is UIWindow
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard
            let recognizers = gestureRecognizer.view?.gestureRecognizers as NSArray?
            where recognizers.containsObject(otherGestureRecognizer)
            else { return false }

        let parentRecognizer = gestureRecognizer
        return recognizers.indexOfObject(parentRecognizer) < recognizers.indexOfObject(otherGestureRecognizer)
    }

}
