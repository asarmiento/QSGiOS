//
//  LogScreen.swift
//  QGS
//
//  Created by Edin Martinez on 3/4/25.
//

import FirebaseAnalytics

class LogScreen: NSObject {
    public static let shared = LogScreen()
    func logScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: "\(type(of: self))"
        ])
    }
}
