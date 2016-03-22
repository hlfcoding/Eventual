//
//  InteractiveZoomTransition.swift
//  Eventual
//
//  Created by Peng Wang on 1/19/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
//

import UIKit

class InteractiveZoomTransition: UIPercentDrivenInteractiveTransition, InteractiveTransition, UIGestureRecognizerDelegate {

    private weak var delegate: TransitionInteractionDelegate?
    private weak var reverseDelegate: TransitionInteractionDelegate?

    var minVelocityThreshold =   (zoomIn: CGFloat(0.5), zoomOut: CGFloat(0.1))
    var maxCompletionThreshold = (zoomIn: CGFloat(0.5), zoomOut: CGFloat(0.3))
    var minScaleDeltaThreshold = (zoomIn: CGFloat(1.0), zoomOut: CGFloat(0.2))
    var minOutDestinationSpanThreshold: CGFloat = 10.0

    var isReversed: Bool = false

    private var pinchRecognizer: UIPinchGestureRecognizer! {
        didSet {
            self.pinchRecognizer.delegate = self
        }
    }
    var pinchWindow: UIWindow!

    var pinchSpan: CGFloat {
        let firstLocation = self.pinchRecognizer.locationOfTouch(0, inView: self.pinchWindow)
        let secondLocation = self.pinchRecognizer.locationOfTouch(1, inView: self.pinchWindow)
        let xSpan = fabs(firstLocation.x - secondLocation.x)
        let ySpan = fabs(firstLocation.y - secondLocation.y)
        return fmax(xSpan, ySpan)
    }
    private var sourceScale: CGFloat?
    private var destinationScale: CGFloat?
    private var isTransitioning = false

    var isEnabled: Bool = false {
        didSet {
            if self.isEnabled {
                self.pinchWindow.addGestureRecognizer(self.pinchRecognizer)
            } else {
                self.pinchWindow.removeGestureRecognizer(self.pinchRecognizer)
            }
        }
    }

    init(delegate: TransitionInteractionDelegate,
         reverseDelegate: TransitionInteractionDelegate? = nil)
    {
        super.init()

        self.delegate = delegate
        self.reverseDelegate = reverseDelegate

        self.pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(InteractiveZoomTransition.handlePinch(_:)))
    }

    @objc @IBAction private func handlePinch(sender: UIPinchGestureRecognizer) {
        var computedProgress: CGFloat?
        let scale = sender.scale, state = sender.state, velocity = sender.velocity
        func tearDown() {
            self.isReversed = false
            self.isTransitioning = false
            self.sourceScale = nil
            self.destinationScale = nil
        }
        print("DEBUG: state: \(state.rawValue), scale: \(scale), velocity: \(velocity)")
        switch state {
        case .Began:
            let isReversed = velocity < 0
            guard self.testAndBeginInTransitionForScale(scale) ||
                  (isReversed && self.testAndBeginOutTransitionForScale(scale))
                  else { break }

            self.isReversed = isReversed
            self.isTransitioning = true
            self.sourceScale = scale

        case .Changed:
            guard let destinationScale = self.destinationScale else { break }
            // TODO: Factor in velocity.
            var percentComplete: CGFloat!
            if self.isReversed {
                percentComplete = destinationScale / scale
            } else {
                percentComplete = scale / destinationScale
            }
            percentComplete = fmax(0.0, fmin(1.0, percentComplete))
            print("DEBUG: percent: \(percentComplete)")
            self.updateInteractiveTransition(percentComplete)

        case .Ended:
            var isCancelled: Bool
            if self.isReversed {
                isCancelled = (
                    fabs(velocity) < self.minVelocityThreshold.zoomOut &&
                    self.percentComplete < self.maxCompletionThreshold.zoomOut
                )
            } else {
                isCancelled = (
                    fabs(velocity) < self.minVelocityThreshold.zoomIn &&
                    self.percentComplete < self.maxCompletionThreshold.zoomIn
                )
            }
            if !isCancelled, let sourceScale = self.sourceScale {
                let delta = fabs(scale - sourceScale)
                isCancelled = delta < self.minScaleDeltaThreshold.zoomIn
                if self.isReversed {
                    isCancelled = delta < self.minScaleDeltaThreshold.zoomOut
                }
                print("DEBUG: delta: \(delta)")
            }
            if isCancelled {
                print("CANCELLED")
                self.cancelInteractiveTransition()
            } else {
                self.finishInteractiveTransition()
            }
            tearDown()

        case .Cancelled:
            self.cancelInteractiveTransition()
            tearDown()

        case .Failed:
            print("FAILED: percent: \(self.percentComplete)")
            tearDown()

        case .Possible:
            fatalError("This should never happen.")
        }
    }

    private func testAndBeginInTransitionForScale(scale: CGFloat) -> Bool {
        guard let delegate = self.delegate else { return false }

        let contextView = delegate.interactiveTransition(self, locationContextViewForGestureRecognizer: pinchRecognizer)
        let location = pinchRecognizer.locationInView(contextView)
        guard let referenceView = delegate.interactiveTransition(self, snapshotReferenceViewAtLocation: location, ofContextView: contextView)
              else { return false }

        self.destinationScale = delegate.interactiveTransition( self,
            destinationScaleForSnapshotReferenceView: referenceView,
            contextView: contextView, reversed: false
        )
        if self.destinationScale < 0 || self.destinationScale == nil {
            self.destinationScale = contextView.frame.width / referenceView.frame.width
        }
        let destinationAmp = referenceView.frame.width / self.pinchSpan
        guard let destinationScale = self.destinationScale else { return false }

        self.destinationScale = destinationScale * destinationAmp
        print("DEBUG: reference: \(referenceView), destination: \(destinationScale)")
        delegate.beginInteractivePresentationTransition(self, withSnapshotReferenceView: referenceView)
        return true
    }

    private func testAndBeginOutTransitionForScale(scale: CGFloat) -> Bool {
        guard let delegate = self.delegate
              where delegate.respondsToSelector("beginInteractiveDismissalTransition:withSnapshotReferenceView:"),
              let reverseDelegate = self.reverseDelegate
              else { return false }

        let contextView = delegate.interactiveTransition(self, locationContextViewForGestureRecognizer: pinchRecognizer)
        if delegate is UIViewController {
            self.destinationScale = reverseDelegate.interactiveTransition( self,
                destinationScaleForSnapshotReferenceView: nil,
                contextView: contextView, reversed: true
            )
        }
        if self.destinationScale == nil || self.destinationScale < 0 {
            self.destinationScale = self.minOutDestinationSpanThreshold / (self.pinchSpan * (1 / scale))
        }
        print("DEBUG: destination: \(self.destinationScale)")
        delegate.beginInteractiveDismissalTransition(self, withSnapshotReferenceView:nil)
        return true
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return otherGestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer.view is UIWindow
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        guard let recognizers = gestureRecognizer.view?.gestureRecognizers as NSArray?
              where recognizers.containsObject(otherGestureRecognizer)
              else { return false }

        let parentRecognizer = gestureRecognizer
        return recognizers.indexOfObject(parentRecognizer) < recognizers.indexOfObject(otherGestureRecognizer)
    }

}
