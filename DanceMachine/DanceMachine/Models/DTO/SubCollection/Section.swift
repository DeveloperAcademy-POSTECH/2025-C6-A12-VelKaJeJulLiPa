//
//  Section.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Section: Codable {
    
    let sectionId: String
    let sectionTitle: String
    
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
}
