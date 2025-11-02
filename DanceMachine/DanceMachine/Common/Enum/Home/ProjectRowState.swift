//
//  ProjectRowState.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/21/25.
//

import SwiftUI

enum ProjectRowState: Equatable {
    case viewing
    case editing(ProjectEditAction)
    
    var primaryTitle: String {
        switch self {
        case .viewing:                 return "편집"
        case .editing(.none):          return "취소"
        case .editing(.delete):        return "취소"
        case .editing(.update):        return "완료"
        }
    }
    var primaryColor: Color {
        switch self {
        case .viewing:                 return .gray
        case .editing(.none):          return .blue
        case .editing(.delete):        return .blue
        case .editing(.update):        return .blue
        }
    }
    // 보조(왼쪽) 버튼이 필요한 경우만 제공
    var secondaryTitle: String? {
        switch self {
        case .editing(.update):        return "취소"
        default:                       return nil
        }
    }
    
    var secondaryColor: Color { .gray }
}
