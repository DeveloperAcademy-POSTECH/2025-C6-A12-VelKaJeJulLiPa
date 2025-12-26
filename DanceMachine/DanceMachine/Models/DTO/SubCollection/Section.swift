//
//  Section.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Section: Codable, Equatable, Hashable {
    
    let sectionId: String
    var sectionTitle: String
    
    init(
        sectionId: String,
        sectionTitle: String
    ) {
        self.sectionId = sectionId
        self.sectionTitle = sectionTitle
    }
    
    enum CodingKeys: String, CodingKey {
        case sectionId = "section_id"
        case sectionTitle = "section_title"
    }
    
}

extension Section: EntityRepresentable {
    var entityName: CollectionType { .section }
    var documentID: String { sectionId }
    var asDictionary: [String: Any]? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict
    }
}

extension Section {
    /// UI에 표시할 때 사용하는 로컬라이즈된 섹션 타이틀
    /// DB에는 "General"로 저장되지만, 사용자 언어로 번역하여 표시
    /// 기존 "일반" 데이터와의 하위 호환성 유지
    var localizedTitle: String {
        if sectionTitle == "General" || sectionTitle == "일반" {
            return String(localized: "일반")
        }
        return sectionTitle
    }
}
