//
//  KeyboardHelper.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/29/25.
//

import Foundation
import UIKit

enum KeyboardHelper {
  static func dismiss() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
  }
}
