//
//  InviteError.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import Foundation

enum InviteError: LocalizedError {
    /// URLComponents로 공유 URL을 만들지 못한 경우
    case urlBuildFailed
}
