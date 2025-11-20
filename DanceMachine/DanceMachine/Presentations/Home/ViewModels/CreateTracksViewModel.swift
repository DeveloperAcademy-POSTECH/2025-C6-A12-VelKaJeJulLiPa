//
//  CreateTracksViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/22/25.
//

import Foundation

// 곡 이름 검증 결과
struct TrackNameValidationResult {
  let text: String       // 실제로 사용할 텍스트
  let overText: Bool     // 20자를 넘겨서 잘린 적이 있는지 여부
}

@Observable
final class CreateTracksViewModel {
  
  
  /// 곡 이름 입력값을 정제/검증하는 헬퍼
   /// - Parameters:
   ///   - oldValue: 기존 값
   ///   - newValue: 새로 입력된 값
   /// - Returns: 정제된 텍스트 + overText 플래그
   func validateTeamspaceName(oldValue: String, newValue: String) -> TrackNameValidationResult {
     var updated = newValue
     var overText = false
     
     // 1) 첫 글자 공백 막기
     if let first = updated.first, first == " " {
       updated = String(updated.drop(while: { $0 == " " }))
     }
     
     // 2) 20자 초과 여부 체크
     if updated.count > 20 {
       // 기존 로직 유지
       if updated.count == 21 {
         overText = true
       }
       // 앞 20자만 유지
       let limited = String(updated.prefix(20))
       updated = limited
     }
     
     return TrackNameValidationResult(
       text: updated,
       overText: overText
     )
   }
  
  
  
  
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
