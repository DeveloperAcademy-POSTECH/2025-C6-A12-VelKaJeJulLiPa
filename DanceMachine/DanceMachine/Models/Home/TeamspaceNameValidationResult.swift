//
//  TeamspaceNameValidationResult.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/20/25.
//

import Foundation

// 팀 스페이스 이름 검증 결과
struct TeamspaceNameValidationResult {
  let text: String       // 실제로 사용할 텍스트
  let overText: Bool     // 20자를 넘겨서 잘린 적이 있는지 여부
}
