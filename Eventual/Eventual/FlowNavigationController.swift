//
//  FlowNavigationController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class FlowNavigationController: UINavigationController {

    weak var dataSource: MonthEventDataSource?

    var supportedSegues: [Segue] { return [] }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let viewController = sender as? CoordinatedViewController {
            if action == #selector(prepareSegue(_:)),
                let identifier = viewController.currentSegue?.identifier {
                return supportedSegues.contains(Segue(rawValue: identifier)!)
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }

    func ensureAccess(ensuredOperation: @escaping () -> Void) {
        let manager = dataSource!.manager!
        guard manager.hasAccess else {
            let center = NotificationCenter.default
            var observer: NSObjectProtocol?
            observer = center.addObserver(forName: .EntityAccess, object: nil, queue: nil) {
                guard let observer = observer,
                    let payload = $0.userInfo?.notificationUserInfoPayload() as? EntityAccessPayload,
                    payload.result == .granted
                    else { return }
                NotificationCenter.default.removeObserver(observer)
                ensuredOperation()
            }
            manager.requestAccess()
            return
        }
        ensuredOperation()
    }

    func prepareSegue(_ sender: Any?) {
        let viewController = sender as! CoordinatedViewController
        let (_, _, _, destinationContainer, _) = unpackSegue(for: viewController)
        if let navigationController = destinationContainer as? FlowNavigationController {
            navigationController.dataSource = dataSource
        }
    }

    func unpackSegue(for viewController: CoordinatedViewController) -> (
        type: Segue, destination: UIViewController, source: UIViewController,
        destinationContainer: UINavigationController?, sourceContainer: UINavigationController?)
    {
        let segue = viewController.currentSegue!
        let type = Segue(rawValue: segue.identifier!)!
        let destinationContainer = segue.destination as? UINavigationController
        let destination = destinationContainer?.topViewController ?? segue.destination
        let sourceContainer = segue.source.navigationController
        return (type, destination, segue.source, destinationContainer, sourceContainer)
    }

}
