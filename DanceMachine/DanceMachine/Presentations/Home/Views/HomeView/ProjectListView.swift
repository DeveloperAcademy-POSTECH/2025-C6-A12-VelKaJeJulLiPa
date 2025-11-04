//
//  ProjectListView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct ProjectListView<ExpandedContent: View>: View {
  
  @Bindable var viewModel: HomeViewModel
  
  @Binding var labelText: String
  
  @Binding var projects: [Project]
  @Binding var rowState: ProjectRowState
  @Binding var editingProjectID: UUID?
  @Binding var editText: String
  
  let onCommitEdit: (_ projectId: UUID, _ newName: String) async -> Void
  let onDelete: (_ project: Project) -> Void
  let onTap: (_ project: Project) -> Void
  
  
  let isExpanded: (Project) -> Bool
  let expandedContent: (Project) -> ExpandedContent
  
  
  // ① 현재 “어떤 헤더를 보여줄지”를 부모가 알려줌
  let isAnyProjectExpanded: Bool
  
  // ② 트랙 헤더용 바인딩/콜백
  @Binding var tracksRowState: TracksRowState
  let isTracksPrimaryDisabled: Bool
  let onTracksPrimaryUpdate: () -> Void
  let onTracksCancelSideEffects: () -> Void
  
  
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // 헤더: 프로젝트가 펼쳐져 있으면 TracksRowState를, 아니면 ProjectRowState를 바인딩
      if isAnyProjectExpanded {
        ProjectListHeaderView(
          viewModel: viewModel,
          state: $tracksRowState,
          labelText: $labelText, // 예: 선택 프로젝트명
          isPrimaryDisabled: isTracksPrimaryDisabled,
          onPrimaryUpdate: onTracksPrimaryUpdate,
          onCancelSideEffects: onTracksCancelSideEffects
        )
      } else {
        ProjectListHeaderView(
          viewModel: viewModel,
          state: $rowState,
          labelText: $labelText, // “프로젝트 목록”
          isPrimaryDisabled: shouldDisablePrimaryButton,
          onPrimaryUpdate: { Task { await commitIfPossible() } },
          onCancelSideEffects: { clearEditingBuffers(keepText: rowState.isUpdating) }
        )
      }
      
      if projects.isEmpty {
        emptyView
      } else {
        List(projects, id: \.projectId) { project in
          VStack(spacing: 8) {
            ListCell(
              title: project.projectName,
              projectRowState: perRowState(for: project.projectId),
              deleteAction: { onDelete(project) },
              editAction: {
                editText         = project.projectName
                editingProjectID = project.projectId
                rowState         = .editing(.update)
              },
              rowTapAction: { onTap(project) },
              editText: Binding(
                get: { (editingProjectID == project.projectId) ? editText : project.projectName },
                set: { if editingProjectID == project.projectId { editText = $0 } }
              ),
              isExpanded: isExpanded(project)
            )
            .listRowSeparator(.hidden)
            
            
            if isExpanded(project) {
              expandedContent(project)
                .padding(.leading, 20)
            }
          }
          .animation(.easeInOut, value: isExpanded(project))
          .listRowBackground(Color.backgroundNormal)
          .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .background(Color.backgroundNormal)
      }
    }
  }
  
  /// 프로젝트 이름 편집을 커밋합니다.
  /// - Note: 현재 행 상태가 업데이트(editing(.update))이고, 편집 대상 ID와 유효한 이름이 존재할 때만 동작합니다.
  /// - Behavior:
  ///   1) 공백을 제거한 이름이 비어 있으면 아무 것도 하지 않습니다.
  ///   2) 부모에서 주입한 `onCommitEdit` 비동기 콜백을 호출해 저장을 위임합니다.
  ///   3) 성공 시 편집 버퍼를 지우고 행 상태를 `.viewing`으로 되돌립니다.
  private func commitIfPossible() async {
    guard case .editing(.update) = rowState, let pid = editingProjectID else { return }
    let name = editText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }
    await onCommitEdit(pid, name)
    clearEditingBuffers(keepText: false)
    rowState = .viewing
  }
  
  /// 특정 프로젝트 셀에 적용할 행 상태를 계산합니다.
  /// - Parameter projectID: 상태를 계산할 프로젝트의 식별자.
  /// - Returns: 전체 헤더의 편집 상태(`rowState`)와 현재 편집 중인 ID(`editingProjectID`)를 고려한 per-row 상태.
  /// - Discussion: 목록 전체는 업데이트 중이더라도, 해당 셀이 편집 대상이 아니면 `.editing(.none)`을 반환해 일반 모드로 유지합니다.
  private func perRowState(for projectID: UUID) -> ProjectRowState {
    switch rowState {
    case .viewing:          return .viewing
    case .editing(.none):   return .editing(.none)
    case .editing(.delete): return .editing(.delete)
    case .editing(.update): return (editingProjectID == projectID) ? .editing(.update) : .editing(.none)
    }
  }
  
  /// 헤더의 기본(primary) 버튼 비활성화 여부를 계산합니다.
  /// - Returns: 이름 변경 커밋 단계(`.editing(.update)`)에서 편집 텍스트가 비어 있으면 `true`, 그 외에는 `false`.
  /// - Important: 버튼 비활성화는 단순한 UI 상태이므로 실제 커밋 방어 로직은 `commitIfPossible()`에서도 한 번 더 수행합니다.
  private var shouldDisablePrimaryButton: Bool {
    if case .editing(.update) = rowState {
      return editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    return false
  }
  
  /// 편집 버퍼를 초기화합니다.
  /// - Parameter keepText: `true`면 텍스트를 유지하고, `false`면 텍스트를 공란으로 초기화합니다.
  /// - Side Effects: `editingProjectID`는 언제나 `nil`로 초기화됩니다.
  private func clearEditingBuffers(keepText: Bool) {
    editingProjectID = nil
    if !keepText { editText = "" }
  }
  
  /// 프로젝트가 하나도 없을 때 표시되는 자리 표시자 뷰입니다.
  /// - Design: 큰 아이콘과 보조 문구로 빈 상태를 명확히 전달합니다.
  private var emptyView: some View {
    VStack(spacing: 10) {
      Spacer()
      Image(systemName: "archivebox.fill")
        .font(.system(size: 110))
        .foregroundStyle(Color.fillAssitive)
        .frame(maxWidth: .infinity)
      Text("프로젝트가 없습니다.")
        .font(.headline2Medium) // FIXME: - 폰트 수정
        .foregroundStyle(Color.labelAssitive) // FIXME: - 컬러 수정
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .center)
  }
}

#Preview {
  PreviewWrapper()
}


// MARK: - 프리뷰

private struct PreviewWrapper: View {
  // ViewModel & Bindings for preview
  @State private var vm = HomeViewModel()
  
  @State private var labelText: String = "프로젝트 목록"
  
  @State private var projects: [Project] = [
    Project(
      projectId: UUID(),
      teamspaceId: "teamspace-demo-001",
      creatorId: "user-demo-alice",
      projectName: "뉴진스 - Hype Boy"
    ),
    Project(
      projectId: UUID(),
      teamspaceId: "teamspace-demo-001",
      creatorId: "user-demo-bob",
      projectName: "아이브 - Love Dive"
    ),
    Project(
      projectId: UUID(),
      teamspaceId: "teamspace-demo-002",
      creatorId: "user-demo-charlie",
      projectName: "르세라핌 - Easy"
    )
  ]
  
  @State private var rowState: ProjectRowState = .viewing
  @State private var editingProjectID: UUID? = nil
  @State private var editText: String = ""
  
  // Tracks 헤더 전환용
  @State private var tracksRowState: TracksRowState = .viewing
  
  // 어떤 프로젝트가 펼쳐졌는지 (미니 라우터처럼 사용)
  @State private var expandedID: UUID? = nil
  
  var body: some View {
    ProjectListView(
      viewModel: vm,
      labelText: $labelText,
      projects: $projects,
      rowState: $rowState,
      editingProjectID: $editingProjectID,
      editText: $editText,
      onCommitEdit: { _, _ in /* no-op for preview */ },
      onDelete: { _ in /* no-op for preview */ },
      onTap: { project in
        // 토글 + 헤더 타이틀 동기화
        if expandedID == project.projectId {
          expandedID = nil
          labelText = "프로젝트 목록"
        } else {
          expandedID = project.projectId
          labelText = project.projectName
        }
      },
      isExpanded: { project in
        expandedID == project.projectId
      },
      expandedContent: { project in
        // 펼쳐졌을 때 보여줄 임시 콘텐츠 (실제에선 TracksInlineView 등)
        VStack(alignment: .leading, spacing: 8) {
          Text("Tracks for \(project.projectName)")
            .font(.headline)
          Text("여기에 TracksInlineView가 들어갑니다.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
      },
      // 헤더 전환 판단값
      isAnyProjectExpanded: expandedID != nil,
      // Tracks 헤더 바인딩/콜백
      tracksRowState: $tracksRowState,
      isTracksPrimaryDisabled: false,
      onTracksPrimaryUpdate: {},
      onTracksCancelSideEffects: {}
    )
    .padding()
  }
}



