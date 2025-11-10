//
//  ToastIcon.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import SwiftUI

enum ToastIcon: String {
  case warning
  case check

  var icon: String {
    switch self {
    case .warning: return "exclamationmark.circle.fill"
    case .check: return "checkmark.circle.fill"
    }
  }

  var iconColor: Color {
    switch self {
    case .warning: return .accentRedNormal
    case .check: return .secondaryNormal
    }
  }
}
