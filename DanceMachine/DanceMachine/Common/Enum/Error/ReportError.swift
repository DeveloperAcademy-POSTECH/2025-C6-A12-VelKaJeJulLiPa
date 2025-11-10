//
//  ReportError.swift
//  DanceMachine
//
//  Created by Paidion on 11/10/25.
//

import Foundation


enum ReportError: LocalizedError {
    case reportFailed(underlying: Swift.Error)
    case unknown(underlying: Swift.Error)
    
    var errorDescription: String? {
      switch self {
      case .reportFailed(let error):
        return "신고 업로드에 실패했습니다.: \(error)"
      case .unknown(let error):
        return error.localizedDescription
      }
    }
  }
