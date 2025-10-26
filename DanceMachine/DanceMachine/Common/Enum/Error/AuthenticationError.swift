//
//  AuthenticationError.swift
//  DanceMachine
//
//  Created by Paidion on 10/26/25.
//

import Foundation

enum AuthenticationError: LocalizedError {
    
    case userNotFound
    case lastSignInDateMissing
    case signOutFailed(underlying: Swift.Error)
    case reauthenticationFailed(underlying: Swift.Error)
    case appleAuthorizationFailed
    case revokeTokenFailed(underlying: Swift.Error)
    case userAccountDeleteFailed(underlying: Swift.Error)
    case unknown(error: Swift.Error)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다."
        case .lastSignInDateMissing:
            return "마지막 로그인 정보를 불러올 수 없습니다."
        case .signOutFailed(let error):
            return "로그아웃에 실패했습니다: \(error.localizedDescription)"
        case .reauthenticationFailed(let error):
            return "계정 재인증에 실패했습니다: \(error.localizedDescription)"
        case .appleAuthorizationFailed:
            return "Apple 인증 과정에서 문제가 발생했습니다"
        case .revokeTokenFailed(let error):
            return "Apple 로그인 토큰을 취소하는 중 문제가 발생했습니다: \(error.localizedDescription)"
        case .userAccountDeleteFailed(let error):
            return "Firebase 계정 삭제에 실패했습니다: \(error.localizedDescription)"
        case .unknown(let error):
            return "알 수 없는 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
