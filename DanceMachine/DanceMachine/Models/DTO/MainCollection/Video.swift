//
//  Video.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation
import FirebaseFirestore

struct Video: Codable {
    let videoId: UUID
    let videoTitle: String
    let videoDuration: Double
    let videoURL: String
    let thumbnailURL: String
    var createdAt: Date? = nil

    init(
        videoId: UUID,
        videoTitle: String,
        videoDuration: Double,
        videoURL: String,
        thumbnailURL: String,
        createdAt: Date? = nil
    ) {
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.videoDuration = videoDuration
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case videoId       = "video_id"
        case videoTitle    = "video_title"
        case videoDuration = "video_duration"
        case videoURL      = "video_url"
        case thumbnailURL  = "thumbnail_url"
        case createdAt     = "created_at"
    }
}

extension Video: EntityRepresentable {
    var entityName: CollectionType { .video }
    var documentID: String { videoId.uuidString }
}
