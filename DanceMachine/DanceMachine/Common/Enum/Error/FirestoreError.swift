//
//  FirestoreError.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

enum FirestoreError: LocalizedError {
    case addFailed(underlying: Swift.Error)
    case fetchFailed(underlying: Swift.Error)
    case deleteFailed(underlying: Swift.Error)
    case updateFailed(underlying: Swift.Error)
    
    case decodingFailed
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .addFailed(let error):
            String(localized: "데이터를 추가하는데 실패했습니다: \(error)")
        case .fetchFailed(let error):
            String(localized: "데이터를 읽어오는데 실패했습니다: \(error)")
        case .deleteFailed(let error):
            String(localized: "데이터를 삭제하는데 실패했습니다: \(error)")
        case .updateFailed(let error):
            String(localized: "데이터를 업데이트하는데 실패했습니다: \(error)")
        case .encodingFailed:
            String(localized: "데이터를 encoding하는데 실패했습니다")
        case .decodingFailed:
            String(localized: "데이터를 decoding하는데 실패했습니다")
        }
    }
}
