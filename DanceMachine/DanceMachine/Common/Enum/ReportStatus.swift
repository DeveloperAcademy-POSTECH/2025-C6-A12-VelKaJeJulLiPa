//
//  ReportStatus.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

enum ReportStatus: String, Codable {
    case reviewing = "reviewing"
    case resolved  = "resolved"
    case rejected  = "rejected"
}
