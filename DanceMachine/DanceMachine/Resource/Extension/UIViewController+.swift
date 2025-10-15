//
//  UIViewController+.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import Foundation
import AuthenticationServices


extension UIViewController: @retroactive ASAuthorizationControllerPresentationContextProviding {
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
