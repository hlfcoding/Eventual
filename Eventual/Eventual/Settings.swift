//
//  Settings.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation

struct Settings {

    static var shouldTapToAddEvent: Bool {
        return UserDefaults.standard.bool(forKey: "MinimalismAddEvent")
    }

    static func addChangeObserver(_ observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(
            observer, selector: selector,
            name: UserDefaults.didChangeNotification, object: UserDefaults.standard
        )
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "MinimalismAddEvent": true
        ])
    }

}
