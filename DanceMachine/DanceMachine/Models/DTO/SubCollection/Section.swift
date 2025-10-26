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
