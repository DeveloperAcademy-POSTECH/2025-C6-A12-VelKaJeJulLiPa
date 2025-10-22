//
//  UIViewController+.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import Foundation
import AuthenticationServices

/// Sign in with Apple 인증 UI가 표시될 window 반환
extension UIViewController: @retroactive ASAuthorizationControllerPresentationContextProviding {
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
