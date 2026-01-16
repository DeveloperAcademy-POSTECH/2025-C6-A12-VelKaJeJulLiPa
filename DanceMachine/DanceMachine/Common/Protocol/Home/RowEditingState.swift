//
//  RowEditingState.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

//// 공통 인터페이스: 버튼 타이틀/색상, 현재 상태 전환 메서드
//protocol RowEditingState {
//    var primaryTitle: String { get }
//    var secondaryTitle: String? { get }
//    var primaryColor: Color { get }
//    var secondaryColor: Color { get }
//
//    var isUpdating: Bool { get }
//    var isViewing: Bool { get }
//    
//    mutating func enterViewing()
//    mutating func enterEditingNone()
//}

//extension ProjectRowState: RowEditingState {
//    var isUpdating: Bool {
//      if case .editing = self { return true }
//        return false
//    }
//    var isViewing: Bool {
//        if case .viewing = self { return true }
//        return false
//    }
//    mutating func enterViewing() { self = .viewing }
////    mutating func enterEditingNone() { self = .editing(.none) }
//}

extension TracksRowState {
    var isUpdating: Bool {
        if case .editing = self { return true }
        return false
    }
    var isViewing: Bool {
        if case .viewing = self { return true }
        return false
    }
    mutating func enterViewing() { self = .viewing }
    mutating func enterEditingNone() { self = .editing }
}
