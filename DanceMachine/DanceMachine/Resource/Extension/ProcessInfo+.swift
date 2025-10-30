//
//  ProcessInfo+.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/29/25.
//

import Foundation

extension ProcessInfo {
    static var isRunningInPreviews: Bool {
            #if DEBUG
            return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            #else
            return false
            #endif
        }
}
