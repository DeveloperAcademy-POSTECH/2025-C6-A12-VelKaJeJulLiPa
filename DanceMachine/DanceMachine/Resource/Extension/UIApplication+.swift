//
//  UIApplication+.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import Foundation
import SwiftUI

/// 최상단에 표시되고 있는 ViewController 를 가져오기 위한 extension
extension UIApplication {

    /// 앱의 RootViewController 반환
    static private func rootViewController() -> UIViewController? {
        let rootVC: UIViewController? = UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }?
            .rootViewController
        
        return rootVC
    }

    /// 사용자가 보고있는 ViewController 반환
    @MainActor
    static func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let controller = controller ?? rootViewController()

        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }

}
