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
  ///     - projectId: 생성 프로젝트 Id
  ///     - tracksName: 프로젝트 이름 설정
  func createTracks(projectId: String, tracksName: String) async throws {
    do {
      
      // FIXME: - batch 추가하기
      
      let tracks: Tracks = .init(
        tracksId: UUID(),
        projectId: projectId,
        creatorId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
        trackName: tracksName
      )
      try await FirestoreManager.shared.create(tracks)
      
      // 서브컬렉션 section도 같이 생성
      let section: Section = .init(
        sectionId: UUID().uuidString,
        sectionTitle: "일반" // TODO: 디자이너와 이야기 해볼 것
      )
      
      try await FirestoreManager.shared.createToSubcollection(
        section,
        under: .tracks,
        parentId: tracks.tracksId.uuidString,
        subCollection: .section,
        strategy: .create
      )
      
      /// 곡 생성 시, 해당 프로젝트 Update_At을 갱신하는 메서드입니다.
      try await FirestoreManager.shared.updateTimestampField(
        field: .update,
        in: .project,
        documentId: projectId
      )
      
      
    } catch {
      print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 분기 처리
    }
  }
}
