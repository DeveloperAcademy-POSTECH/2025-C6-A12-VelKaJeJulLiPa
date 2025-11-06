//
//  TabCase.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

enum TabCase: String, CaseIterable, Identifiable {
    case home = "홈"
    case inbox = "수신함"
    case myPage = "마이 페이지"
    case custom = "커스텀"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .inbox: return "tray"
        case .myPage: return "person.crop.circle"
        case .custom: return "plus.circle.fill"
        }
    }
}
