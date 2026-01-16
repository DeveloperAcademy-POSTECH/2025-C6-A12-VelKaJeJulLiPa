//
//  Tracks.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Tracks: Codable {
    let tracksId: UUID
    let projectId: String
    let creatorId: String
    var trackName: String

    init(
        tracksId: UUID,
        projectId: String,
        creatorId: String,
        trackName: String
    ) {
        self.tracksId = tracksId
        self.projectId = projectId
        self.creatorId = creatorId
        self.trackName = trackName
    }

    enum CodingKeys: String, CodingKey {
        case tracksId   = "tracks_id"
        case projectId = "project_id"
        case creatorId = "creator_id"
        case trackName = "track_name"
    }
}

extension Tracks: Identifiable {
    var id: String { UUID().uuidString }
}

extension Tracks: EntityRepresentable {
    var entityName: CollectionType { .tracks }
    var documentID: String { tracksId.uuidString }
}
