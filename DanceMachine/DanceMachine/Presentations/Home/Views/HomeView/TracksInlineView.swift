//
//  TracksInlineView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct TracksInlineView: View {
  @Bindable var viewModel: HomeViewModel
  
  let project: Project
  
  @Binding var tracks: [Tracks]
  @Binding var rowState: TracksRowState
  @Binding var editingTrackID: UUID?
  @Binding var editingText: String
  
  let isLoading: Bool
  let errorText: String?
  
  let onCommitEdit: (_ tracksId: UUID, _ newName: String) async -> Void
  let onDelete: (_ track: Tracks) -> Void
  let onTap: (_ track: Tracks) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if isLoading {
        HStack {
          // FIXME: - 트랙 불러오는 중... 디자인 UX 논의
          ProgressView()
        }
      } else if let errorText {
        // FIXME: - 트랙 에러디자인 UX 논의
        ProgressView()
      } else if tracks.isEmpty {
        Text("곡이 없습니다. 추가해보세요")
          .font(.body1Medium)
          .foregroundStyle(.labelAssitive)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity, alignment: .center)
          .background(
            RoundedRectangle(cornerRadius: 15)
              .fill(Color.fillNormal)
          )
      } else {
        // 카드 컨테이너
        VStack(spacing: 0) {
          ForEach(Array(tracks.enumerated()), id: \.element.tracksId) { index, track in
            
            let currentUserId = FirebaseAuthManager.shared.userInfo?.userId ?? ""
            let teamspaceOwner = viewModel.currentTeamspace?.ownerId ?? ""
            let canEdit = (track.creatorId == currentUserId || teamspaceOwner == currentUserId)
            
            TrackRow(
              track: track,
              rowState: perRowState(for: track.tracksId),
              deleteAction: { onDelete(track) },
              editAction: {
                editingText    = track.trackName
                editingTrackID = track.tracksId
                rowState       = .editing(.update)
              },
              rowTapAction: { onTap(track) },
              editText: Binding(
                get: { (editingTrackID == track.tracksId) ? editingText : track.trackName },
                set: { if editingTrackID == track.tracksId { editingText = $0 } }
              ),
              canEdit: canEdit
            )
            // 여기서는 가로/세로 패딩만 (카드와 텍스트 사이 여백)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
          }
        }
        // 카드 전체 여백
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        // 카드 배경 + 둥근 모서리
        .background(
          Color.fillNormal
        )
        .clipShape(
          RoundedRectangle(cornerRadius: 15)
        )
      }
    }
  }
  
  /// 트랙 이름 수정 커밋을 시도합니다.
  /// - 동작 순서:
  ///   1) 현재 헤더/행 상태가 `.editing(.update)`인지와 편집 대상 `editingTrackID`가 존재하는지 확인합니다.
  ///   2) 사용자가 입력한 `editingText`에서 앞뒤 공백을 제거하고, 비어 있으면 종료합니다.
  ///   3) 유효한 경우 `onCommitEdit(tid, name)` 콜백을 `await`로 호출하여 실제 저장을 위임합니다.
  ///   4) 저장 후 `clearEditingBuffers(keepText: false)`로 편집 버퍼를 정리합니다.
  ///   5) 행 상태를 `.viewing`으로 되돌려 편집 UI를 닫습니다.
  /// - 주의:
  ///   비동기 콜백 실패 처리는 상위 뷰모델/콜백 측에서 수행하는 것을 전제로 합니다.
  private func commitIfPossible() async {
    guard case .editing(.update) = rowState, let tid = editingTrackID else { return }
    let name = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }
    await onCommitEdit(tid, name)
    clearEditingBuffers(keepText: false)
    rowState = .viewing
  }
  
  /// 특정 트랙 셀에 적용할 개별 행 상태를 계산합니다.
  /// - Parameter id: 셀의 `tracksId`.
  /// - Returns: 전체 헤더 상태(`rowState`)를 기반으로,
  ///   - `.editing(.update)`인 경우에만 해당 `id`가 현재 `editingTrackID`와 같을 때 `.editing(.update)`를 반환하고,
  ///     그렇지 않은 셀은 `.editing(.none)`을 반환합니다.
  ///   - 그 외에는 헤더 상태를 그대로 반영합니다.
  /// - 목적:
  ///   한 번에 하나의 셀만 “이름 편집 모드”가 되도록 보장합니다.
  private func perRowState(for id: UUID) -> TracksRowState {
    switch rowState {
    case .viewing:          return .viewing
    case .editing(.none):   return .editing(.none)
    case .editing(.delete): return .editing(.delete)
    case .editing(.update): return (editingTrackID == id) ? .editing(.update) : .editing(.none)
    }
  }
  
  /// 상단 기본 버튼(예: 저장/완료)의 비활성화 여부를 반환합니다.
  /// - Returns:
  ///   헤더 상태가 `.editing(.update)`일 때, `editingText`를 공백 제거 후 비어 있으면 `true`를 반환합니다.
  ///   그 외에는 `false`입니다.
  /// - 참고:
  ///   헤더 컴포넌트에서 `.disabled(shouldDisablePrimaryButton)`와 함께 사용됩니다.
  private var shouldDisablePrimaryButton: Bool {
    if case .editing(.update) = rowState {
      return editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    return false
  }
  
  /// 편집 버퍼를 정리합니다.
  /// - Parameter keepText: `true`면 `editingText`를 유지하고, `false`면 초기화합니다.
  /// - 동작:
  ///   항상 `editingTrackID`를 `nil`로 만들고, `keepText == false`일 때만 `editingText`를 빈 문자열로 되돌립니다.
  /// - 사용 시점:
  ///   저장 완료 후 또는 편집 취소 시에 호출해 셀 편집 상태를 종료합니다.
  private func clearEditingBuffers(keepText: Bool) {
    editingTrackID = nil
    if !keepText { editingText = "" }
  }
}




//// MARK: - 프리뷰
//#Preview("TracksInlineView · 기본") {
//  PreviewTracksInlineViewDefault()
//}
//
//#Preview("TracksInlineView · 로딩/에러") {
//  PreviewTracksInlineViewLoadingError()
//}
//
//private struct PreviewTracksInlineViewDefault: View {
//  @State private var vm = HomeViewModel()
//  
//  // 미리 생성해 둔 프로젝트 (tracks의 projectId에 연결)
//  @State private var project: Project = .init(
//    projectId: UUID(),
//    teamspaceId: "teamspace-preview-id",
//    creatorId: "preview-user",
//    projectName: "뉴진스"
//  )
//  
//  // 실제 모델 시그니처에 맞춘 더미 트랙 3개
//  @State private var tracks: [Tracks] = []
//  @State private var rowState: TracksRowState = .viewing
//  @State private var editingTrackID: UUID? = nil
//  @State private var editingText: String = ""
//  
//  init() {
//    let projId = project.projectId.uuidString
//    _tracks = State(initialValue: [
//      Tracks(tracksId: UUID(), projectId: projId, creatorId: "preview-user", trackName: "Hype Boy (1절)"),
//      Tracks(tracksId: UUID(), projectId: projId, creatorId: "preview-user", trackName: "Hype Boy (후렴)"),
//      Tracks(tracksId: UUID(), projectId: projId, creatorId: "preview-user", trackName: "Hype Boy (브릿지)")
//    ])
//  }
//  
//  var body: some View {
//    TracksInlineView(
//      viewModel: vm,
//      project: project,
//      tracks: $tracks,
//      rowState: $rowState,
//      editingTrackID: $editingTrackID,
//      editingText: $editingText,
//      isLoading: false,
//      errorText: nil,
//      onCommitEdit: { id, newName in
//        //                if let idx = tracks.firstIndex(where: { $0.tracksId == id }) {
//        //                    // tracks[idx].trackName = newName
//        //                }
//      },
//      onDelete: { track in
//        tracks.removeAll { $0.tracksId == track.tracksId }
//      },
//      onTap: { track in
//        print("Tapped:", track.trackName)
//      }
//    )
//    .padding()
//    .environmentObject(MainRouter())
//  }
//}
//
//
//private struct PreviewTracksInlineViewLoadingError: View {
//  @State private var vm = HomeViewModel()
//  @State private var project = Project(
//    projectId: UUID(),
//    teamspaceId: "아이브 - IAM",
//    creatorId: "preview-user",
//    projectName: "아이브"
//  )
//  
//  @State private var tracks: [Tracks] = []
//  
//  @State private var rowState: TracksRowState = .viewing
//  @State private var editingTrackID: UUID? = nil
//  @State private var editingText: String = ""
//  
//  var body: some View {
//    VStack(spacing: 24) {
//      // 로딩 상태
//      TracksInlineView(
//        viewModel: vm,
//        project: project,
//        tracks: $tracks,
//        rowState: $rowState,
//        editingTrackID: $editingTrackID,
//        editingText: $editingText,
//        isLoading: true,
//        errorText: nil,
//        onCommitEdit: { _, _ in },
//        onDelete: { _ in },
//        onTap: { _ in }
//      )
//      
//      // 에러 상태
//      TracksInlineView(
//        viewModel: vm,
//        project: project,
//        tracks: $tracks,
//        rowState: $rowState,
//        editingTrackID: $editingTrackID,
//        editingText: $editingText,
//        isLoading: false,
//        errorText: "네트워크 오류로 트랙을 불러오지 못했습니다.",
//        onCommitEdit: { _, _ in },
//        onDelete: { _ in },
//        onTap: { _ in }
//      )
//    }
//    .padding()
//    .environmentObject(MainRouter())
//  }
//}
//
