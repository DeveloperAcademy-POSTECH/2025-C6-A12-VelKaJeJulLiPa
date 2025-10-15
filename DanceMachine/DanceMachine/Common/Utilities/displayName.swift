//
//  displayName.swift
//  DanceMachine
//
//  Created by Paidion on 10/15/25.
//

import Foundation
import AuthenticationServices

/// 사용자 이름을 locale에 알맞게 보여주는 함수입니다.
/// - Parameters:
///     - fullName:  사용자 이름
///     - locale: 사용자 로케일
/// - Returns:
///     - 공백 없는 한중일 이름(CJK) 등 사용자 설정 이름겂에 구조화된 이름으로 판단할 수 없다면,  "Unknown"을 반환합니다.
func displayName(from fullName: String?, locale: Locale = .current) -> String {
    guard let fullName = fullName,
          let nameComponents = PersonNameComponentsFormatter().personNameComponents(from: fullName) else {
        return "Unknown"
    }
    
    let formatter = PersonNameComponentsFormatter()
    formatter.style = .medium
    formatter.locale = locale
    
    return formatter.string(from: nameComponents)
}

