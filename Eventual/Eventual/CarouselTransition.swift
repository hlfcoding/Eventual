//
//  CarouselTransition.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol CarouselTransitionDelegate: NSObjectProtocol {

    var carouselContainerView: UIView { get }
    var selectedView: UIView? { get }

    func shiftSelectedIndex() -> Bool

}

class CarouselTransition: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {

    weak var selectedView: UIView? {
        didSet {
            guard !isInteractivelyTransitioning else { return }
            panRecognizer.view?.removeGestureRecognizer(panRecognizer)
            selectedView?.addGestureRecognizer(panRecognizer)
        }
    }

    fileprivate weak var delegate: CarouselTransitionDelegate?

    var direction: ScrollDirectionX = .right

    private(set) var isInteractivelyTransitioning = false

    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panRecognizer.delegate = self
        return panRecognizer
    }()

    private var shouldFinishInteractiveTransition = false

    init(delegate: CarouselTransitionDelegate) {
        super.init()
        self.delegate = delegate
    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!.superview!)
        let velocity = sender.velocity(in: sender.view!)
        switch sender.state {
        case .began:
            direction = velocity.x < 0 ? .right : .left
            isInteractivelyTransitioning = true
            if !delegate!.shiftSelectedIndex() {
                cancel()
            }
        case .changed:
            guard isInteractivelyTransitioning else { break }
            var ratio = translation.x / delegate!.carouselContainerView.frame.width
            if (direction == .right && ratio > 0) || (direction == .left && ratio < 0) {
                ratio = 0
            }
            ratio = min(max(abs(ratio), 0), 0.99)
            shouldFinishInteractiveTransition = ratio > 0.5
            update(ratio)
        case .ended, .cancelled:
            guard isInteractivelyTransitioning else { break }
            if !shouldFinishInteractiveTransition && abs(velocity.x) > 200 {
                shouldFinishInteractiveTransition = true
            }
//            if !shouldFinishInteractiveTransition || sender.state == .cancelled {
//                reverseDirection()
//                shiftSelectedIndex()
//                isInteractivelyTransitioning = false
//                cancel()
//            } else {
                isInteractivelyTransitioning = false
                selectedView = delegate!.selectedView
                completionCurve = .easeOut
                finish()
//            }
        default: break
        }
    }

    private func reverseDirection() {
        direction = direction == .right ? .left : .right
    }

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panRecognizer, let view = panRecognizer.view?.superview
            else { return true }
        let translation = panRecognizer.translation(in: view)
        let velocity = panRecognizer.velocity(in: panRecognizer.view!)
        return abs(translation.y) < 5 && abs(velocity.y) < 100
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panRecognizer, let view = panRecognizer.view?.superview
            else { return true }
        let translation = panRecognizer.translation(in: view)
        return abs(translation.x) < 5
    }

}

// MARK: UIViewControllerAnimatedTransitioning

extension CarouselTransition: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return (transitionContext?.isAnimated == true) ? 0.3 : 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to)
            else { return transitionContext.completeTransition(false) }
        containerView.addSubview(toView)
        let containerWidth = delegate!.carouselContainerView.frame.width
        fromView.frame.origin.x = 0
        toView.frame.origin.x = ((direction == .left) ? -1 : 1) * containerWidth
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0, options: [.curveEaseOut],
            animations: {
                fromView.frame.origin.x = ((self.direction == .left) ? 1 : -1) * containerWidth
                toView.frame.origin.x = 0
        }) { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

}
