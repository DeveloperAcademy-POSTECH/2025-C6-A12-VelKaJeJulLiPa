//
//  HangulUtility.swift
//  DanceMachine
//
//  Created by Paidion on 11/21/25.
//

import Foundation

/// 한글 종성 여부를 기반으로 올바른 조사를 붙여주는 메서드
/// rule 문자열은 반드시 "을/를", "이/가", "은/는", "과/와" 와 같은 형태여야 합니다.
/// # 예시
/// 두 문서를 한꺼번에 삭제하는 경우
/// ```swift
/// josa("리비", "이/가") // "리비가"
/// josa("파이디온", "이/가") // "파이디온이"
/// josa("필통", "와/과") // "필통과"
/// josa("연필", "을/를") // "연필을"
/// josa("Apple", "이/가") // "Apple이" -> 외국어, 알파벳 등은 '모음으로 끝난 것' 취급
/// ```
func josa(_ word: String, _ rule: String) -> String {
    let parts = rule.split(separator: "/")
    guard parts.count == 2 else { return word + rule }

    let front = String(parts[0])  // 받침 O
    let back = String(parts[1])   // 받침 X

    guard let last = lastCharacter(word) else {
        return word + back
    }

    // 한글이 아닌 경우 — 조사 판단하지 않고 항상 뒤에 있는 조사 사용
    guard isHangulSyllable(last) else {
        return word + back
    }

    // 한글인 경우 — 종성 판단
    let hasBatchim = hasFinalConsonant(last)
    var index = hasBatchim ? 0 : 1

    // 와/과는 반전 규칙 적용
    if rule == "와/과" {
        index = (index == 0 ? 1 : 0)
    }

    return word + (index == 0 ? front : back)
}

/// 마지막 문자 가져오기 (이모지도 하나의 Character로 처리됨)
private func lastCharacter(_ text: String) -> Character? {
    return text.last
}

/// 한글 음절인지 판별 (가~힣)
private func isHangulSyllable(_ ch: Character) -> Bool {
    guard let scalar = ch.unicodeScalars.first?.value else { return false }
    return (0xAC00...0xD7A3).contains(scalar)
}

/// 종성 여부 판단
private func hasFinalConsonant(_ ch: Character) -> Bool {
    let scalar = ch.unicodeScalars.first!.value
    let diff = scalar - 0xAC00
    let jong = diff % 28
    return jong != 0
}
