//
//  HapticManager.swift
//  DanceMachine
//
//  Created by Paidion on 11/5/25.
//

import UIKit

/// 햅틱 피드백 종류
enum HapticType {
    case light, medium, heavy, soft, rigid
    case success, warning, error
    case custom(CGFloat) // 0.0 ~ 1.0 사이 강도 지정
}

/// 햅틱을 전역적으로 사용할 수 있는 클래스
final class HapticManager {
    static let shared = HapticManager()
    private init() {
        prepareAllGenerators()
    }

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    private func prepareAllGenerators() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        soft.prepare()
        rigid.prepare()
        notification.prepare()
    }

    // 햅틱 발생 메서드
    func trigger(_ type: HapticType) {
        guard !ProcessInfo.processInfo.isLowPowerModeEnabled else { return }

        switch type {
        case .light:
            light.impactOccurred()
        case .medium:
            medium.impactOccurred()
        case .heavy:
            heavy.impactOccurred()
        case .soft:
            soft.impactOccurred()
        case .rigid:
            rigid.impactOccurred()
        case .success:
            notification.notificationOccurred(.success)
        case .warning:
            notification.notificationOccurred(.warning)
        case .error:
            notification.notificationOccurred(.error)
        case .custom(let intensity):
            medium.impactOccurred(intensity: intensity)
        }

        prepareAllGenerators()
    }
}
