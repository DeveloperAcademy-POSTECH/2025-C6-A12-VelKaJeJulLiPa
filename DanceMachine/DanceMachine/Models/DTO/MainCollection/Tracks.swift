//
//  Tracks.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Tracks: Codable {
    let trackId: UUID
    let projectId: String
    let creatorId: String
    let trackName: String

    init(
        trackId: UUID,
        projectId: String,
        creatorId: String,
        trackName: String
    ) {
        self.trackId = trackId
        self.projectId = projectId
        self.creatorId = creatorId
        self.trackName = trackName
    }

    enum CodingKeys: String, CodingKey {
        case trackId   = "track_id"
        case projectId = "project_id"
        case creatorId = "creator_id"
        case trackName = "track_name"
    }
}

extension Tracks: EntityRepresentable {
    var entityName: CollectionType { .tracks }
    var documentID: String { trackId.uuidString }
}
