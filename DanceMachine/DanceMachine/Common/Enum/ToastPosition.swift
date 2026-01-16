
//
//  ToastPosition.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/5/25.
//

import SwiftUI

enum ToastPosition {
  case top, center, bottom
  var alignment: Alignment {
    switch self {
    case .top:
      return .top
    case .center:
      return .center
    case .bottom:
      return .bottom
    }
  }
}
