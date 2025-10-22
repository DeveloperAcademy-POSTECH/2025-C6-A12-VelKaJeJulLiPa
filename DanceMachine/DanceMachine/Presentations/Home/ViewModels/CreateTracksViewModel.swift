//
//  CreateTracksViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/22/25.
//

import Foundation

@Observable
final class CreateTracksViewModel {
    
    
    
    
    /// 프로젝트의 곡(Treacks)을 생성하는 메서드입니다.
    /// - Parameters:
    ///     - creatorId: 프로젝트 생성 유저의 Id
    ///     - tracksName: 프로젝트 이름 설정
    func createTracks(projectId: String, tracksName: String) async throws {
        do {
            let tracks: Tracks = .init(
                trackId: UUID(),
                projectId: projectId,
                creatorId: MockData.userId, // FIXME: - 데이터 교체
                trackName: tracksName
            )
            tracks.trackId.uuidString
            try await FirestoreManager.shared.create(tracks)
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 분기 처리
        }
    }
    
    
//    // 조회 임시
//    func a(trackId: String) async throws -> Tracks {
//        let tracks: Tracks = try await FirestoreManager.shared.get(
//            trackId,
//            from: .tracks
//        )
//    }
    
}
