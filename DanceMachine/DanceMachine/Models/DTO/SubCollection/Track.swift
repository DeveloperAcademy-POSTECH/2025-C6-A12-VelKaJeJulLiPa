//
//  Track.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Track: Codable {
    
    let trackId: String
    let videoId: String
    var sectionId: String
    
    init(
        trackId: String,
        videoId: String,
        sectionId: String,
    ) {
        self.trackId = trackId
        self.videoId = videoId
        self.sectionId = sectionId
    }
    
    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
        case videoId = "video_id"
        case sectionId = "section_id"
    }
    
}

extension Track: EntityRepresentable {
    var entityName: CollectionType { .track }
    var documentID: String { trackId }
}
