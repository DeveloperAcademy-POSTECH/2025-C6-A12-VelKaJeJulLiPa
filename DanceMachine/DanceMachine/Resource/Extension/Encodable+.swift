//
//  Encodable+.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

extension Encodable {
    /// Encodable → [String: Any] 변환 (간단 버전: JSONEncoder)
    var asDictionary: [String: Any]? {
        guard let object = try? JSONEncoder().encode(self),
              let dictionary = try? JSONSerialization.jsonObject(with: object, options: [])
                as? [String: Any] else {
            return nil
        }
        
        return dictionary
    }
}
