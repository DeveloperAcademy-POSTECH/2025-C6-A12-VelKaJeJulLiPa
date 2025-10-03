//
//  Video.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Video: Codable {
    let videoId: UUID
    let videoTitle: String
    let videoDuration: Double
    let videoURL: String

    init(
        videoId: UUID,
        videoTitle: String,
        videoDuration: Double,
        videoURL: String
    ) {
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.videoDuration = videoDuration
        self.videoURL = videoURL
    }

    enum CodingKeys: String, CodingKey {
        case videoId       = "video_id"
        case videoTitle    = "video_title"
        case videoDuration = "video_duration"
        case videoURL      = "video_url"
    }
}

extension Video: EntityRepresentable {
    var entityName: CollectionType { .video }
    var documentID: String { videoId.uuidString }
}
