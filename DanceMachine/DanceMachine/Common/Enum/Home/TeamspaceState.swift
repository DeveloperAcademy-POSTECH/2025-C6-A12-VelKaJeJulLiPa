//
//  TeamspaceState.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/29/25.
//

import Foundation

/// 팀스페이스의 데이터 유무를 표현하는 상태.
/// - empty: 팀스페이스가 비어 있음
/// - nonEmpty: 팀스페이스에 하나 이상의 데이터가 존재함
enum TeamspaceState {
    case empty
    case nonEmpty
}
