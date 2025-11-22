//
//  ProjectListView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct ProjectListView: View {
  
  @EnvironmentObject private var router: MainRouter
  @Environment(\.cacheStore) private var cacheStore
  
  @Bindable var homeViewModel: HomeViewModel
  @Bindable var projectListViewModel: ProjectListViewModel
  @Binding  var tracksViewModel: TracksListViewModel? // FIXME: - 확인 필요
  
  @State private var isRefreshing: Bool = false
  
  @State private var failDeleteTrack: Bool = false
  @State private var failEditTrack: Bool = false
  @State private var failDeleteProject: Bool = false
  @State private var failEditProject: Bool = false
  
  /// 유저 삭제 권한 판별 변수
  private var canCurrentUserDeletePendingTrack: Bool {
    guard let currentUserId = homeViewModel.currentUserId else { return false }
    
    let ownerId = homeViewModel.currentTeamspace?.ownerId
    let creatorId = tracksViewModel?.alertState.pendingDeleteTrack?.creatorId ?? ""
    
    return ownerId == currentUserId || creatorId == currentUserId
  }
  
  // 곡 수정 권한 체크
  private func canCurrentUserEdit(track: Tracks) -> Bool {
    guard let currentUserId = homeViewModel.currentUserId else { return false }

    let ownerId = homeViewModel.currentTeamspace?.ownerId
    let creatorId = track.creatorId

    return ownerId == currentUserId || creatorId == currentUserId
  }
  
  /// 프로젝트 삭제 권한 판별 변수 (삭제 Alert에서 사용)
  private var canCurrentUserDeletePendingProject: Bool {
    guard let currentUserId = homeViewModel.currentUserId else { return false }

    let ownerId = homeViewModel.currentTeamspace?.ownerId
    let creatorId = projectListViewModel.presentationState
      .pendingDeleteProject?.creatorId ?? ""

    return ownerId == currentUserId || creatorId == currentUserId
  }

  /// 프로젝트 수정/삭제 권한 체크 (row/스와이프에서 사용)
  private func canCurrentUserEdit(project: Project) -> Bool {
    guard let currentUserId = homeViewModel.currentUserId else { return false }

    let ownerId = homeViewModel.currentTeamspace?.ownerId
    let creatorId = project.creatorId

    return ownerId == currentUserId || creatorId == currentUserId
  }
  
  
  fileprivate struct Layout {
    enum EmptyProjectView {
      static let imageName: String = "folder.fill.badge.plus"
      static let imageSize: CGFloat = 110
      static let vstackSpacing: CGFloat = 24
      static let titleText: String = "프로젝트를 추가해보세요."
    }
  }
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(alignment: .leading, spacing: 12) {
        if projectListViewModel.dataState.projects.isEmpty {
          emptyView
        } else {
          projectListHeaderView
            .padding(.horizontal, 24)
          projectListView
        }
      }
    }
    .task { await projectListViewModel.onAppear(cacheStore: cacheStore) }
    .projectListModals(
        homeViewModel: homeViewModel,
        projectListViewModel: projectListViewModel,
        tracksViewModel: $tracksViewModel,
        failDeleteTrack: $failDeleteTrack,
        failEditTrack: $failEditTrack,
        failDeleteProject: $failDeleteProject,
        failEditProject: $failEditProject,
        canDeletePendingTrack: { canCurrentUserDeletePendingTrack },
        canDeletePendingProject: { canCurrentUserDeletePendingProject }
      )
    // 곡 삭제 Alert
    .alert(
      "\(tracksViewModel?.alertState.pendingDeleteTrack?.trackName ?? "") 곡을 삭제하시겠어요?",
      isPresented: Binding(
        get: { tracksViewModel?.alertState.isPresentingDeleteAlert ?? false },
        set: { tracksViewModel?.alertState.isPresentingDeleteAlert = $0 }
      )
    ) {
      Button("취소", role: .cancel) {}
      Button("삭제", role: .destructive) {
        guard canCurrentUserDeletePendingTrack else {
          self.failDeleteTrack = true // 곡 삭제 불가
          return
        }
        // 삭제 가능
        Task {
          await tracksViewModel?.confirmDelete()
        }
      }
    } message: {
      Text("곡 안의 모든 내용이 삭제됩니다.")
    }
    
    // 곡 삭제 불가능 Alert
    .alert(
      "곡 삭제 권한이 없습니다.",
      isPresented: $failDeleteTrack
    ) {
      Button("확인", role: .cancel) {}
    }
  }
  
  // MARK: - 프로젝트 리스트가 비어져있을 때
  
  private var emptyView: some View {
    VStack(spacing: Layout.EmptyProjectView.vstackSpacing) {
      Spacer()
      Button {
        projectListViewModel.presentationState.presentingCreateProjectSheet = true
      } label: {
        Image(systemName: Layout.EmptyProjectView.imageName)
          .font(.system(size: Layout.EmptyProjectView.imageSize))
          .foregroundStyle(Color.secondaryNormal)
          .frame(maxWidth: .infinity)
      }
      Text(Layout.EmptyProjectView.titleText)
        .font(.headline2Medium)
        .foregroundStyle(Color.secondaryAssitive)
      Spacer()
    }
  }
  
  
  // MARK: - 프로젝트 헤더 뷰
  private var projectListHeaderView: some View {
    // 트랙 수정 중인지
    let isTrackEditing = (tracksViewModel?.editingState.rowState == .editing)
    let isProjectEditing = (projectListViewModel.editingState.rowState == .editing)
    
    // 헤더가 editing 모드인지 (프로젝트 or 트랙)
    let isHeaderEditing = isProjectEditing || isTrackEditing
    
    // 헤더 타이틀
    let headerLabelText: String = {
      if isProjectEditing { return "프로젝트 목록" }
      if isTrackEditing { return "프로젝트 목록" }
      return "프로젝트"
    }()
    
    // 체크 버튼 disable 조건
    let headerPrimaryDisabled: Bool = {
      if isProjectEditing {
        return projectListViewModel.isPrimaryButtonDisabled()
      }
      if let tracksVM = tracksViewModel, isTrackEditing {
        return tracksVM.editingState.editText
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .isEmpty
      }
      return false
    }()
    
    return ProjectListHeaderView(
      viewModel: projectListViewModel,
      labelText: headerLabelText,
      isPrimaryDisabled: headerPrimaryDisabled,
      isEditing: isHeaderEditing,
      onPrimaryUpdate: {
        if isProjectEditing {
          Task { await projectListViewModel.commitIfPossible() }
        } else if let tracksVM = tracksViewModel, isTrackEditing {
          Task { await tracksVM.commitIfPossible() }
        }
      }
    )
  }
  
  // MARK: - 프로젝트 리스트 뷰 ( 트랙 뷰 포함 )
  private var projectListView: some View {
    List {
      ForEach(projectListViewModel.dataState.projects, id: \.projectId) { project in
        projectRow(project)
      }
    }
    .listStyle(.plain)
    .background(Color.backgroundNormal)
    .refreshable {
      isRefreshing = true
      defer { isRefreshing = false }
      
      await MainActor.run {
        projectListViewModel.clearAllTracksCache() // 프로젝트별 tracksVM 캐시 제거
        tracksViewModel?.clearCache()
        tracksViewModel = nil
      }
      
      await homeViewModel.onAppear()
      await projectListViewModel.onAppear()
      await tracksViewModel?.onAppear()
      
      // FIXME: - 확인 필요
      if let tracksVM = tracksViewModel,
         tracksVM.project != nil {
        await tracksVM.loadTracks(forceRefresh: true)
      }
      
      // 만약 지금 프로젝트가 펼쳐진 상태면, 그 프로젝트의 tracksVM을 다시 붙여서 강제 로드
      if let expandedId = projectListViewModel.editingState.expandedId,
         let expandedProject = projectListViewModel.dataState.projects.first(where: { $0.projectId == expandedId }) {
        
        let vm = await MainActor.run {
          projectListViewModel.tracksViewModel(for: expandedProject)
        }
        tracksViewModel = vm
        await vm.loadTracks(forceRefresh: true)
      }
    }
    .overlay(alignment: .top) {
      if isRefreshing {
        LoadingSpinner()
          .frame(width: 24, height: 24)
          .padding(.top, 8)
      }
    }
  }
  
  // MARK: - 프로젝트 row
  @ViewBuilder
  private func projectRow(_ project: Project) -> some View {
    let perRowState   = projectListViewModel.perRowState(for: project.projectId)
    let isExpanded    = projectListViewModel.editingState.expandedId == project.projectId
    let isAnyExpanded = projectListViewModel.editingState.expandedId != nil
    
    ListCell(
      projectRowState: perRowState,
      title: project.projectName,
      deleteAction: { projectListViewModel.requestDelete(project: project) },
      editAction: {
        guard canCurrentUserEdit(project: project) else {
          self.failEditTrack = true
          return
        }
        projectListViewModel.startEditing(project: project)
      },
      rowTapAction: {
        projectListViewModel.tapRow(project)
        projectListViewModel.toggleExpand(project)
        
        if projectListViewModel.editingState.expandedId == project.projectId {
          //tracksViewModel = TracksListViewModel(project: project)
          tracksViewModel = projectListViewModel.tracksViewModel(for: project)
        } else {
          tracksViewModel = nil
        }
      },
      editText: Binding(
        get: {
          (projectListViewModel.editingState.editingId == project.projectId)
          ? projectListViewModel.editingState.editText
          : project.projectName
        },
        set: { newValue in
          if projectListViewModel.editingState.editingId == project.projectId {
            projectListViewModel.editingState.editText = newValue
          }
        }
      ),
      isExpanded: isExpanded,
      showToastMessage: $projectListViewModel.presentationState.showNameLengthToast
    )
    .listRowBackground(Color.backgroundNormal)
    .listRowSeparator(.hidden)
    .conditionalSwipeActions(
      enabled: projectListViewModel.editingState.rowState == .viewing && !isAnyExpanded,
      edge: .trailing,
      allowsFullSwipe: false
    ) {
      Button(role: .destructive) {
        projectListViewModel.requestDelete(project: project)
      } label: {
        Label("삭제", systemImage: "trash.fill")
      }
      
      Button {
        guard canCurrentUserEdit(project: project) else {
          self.failEditProject = true
          return
        }
        projectListViewModel.startEditing(project: project)
      } label: {
        Label("수정", systemImage: "pencil")
      }
    }
    
    if isExpanded {
      expandedTracksSection(for: project)
    }
  }
  
  // MARK: - 확장된 트랙 섹션
  @ViewBuilder
  private func expandedTracksSection(for project: Project) -> some View {
    
    if let tracksVM = tracksViewModel,
       tracksVM.project?.projectId == project.projectId {
      
      let tracks    = tracksVM.dataState.tracks
      let hasTracks = !tracks.isEmpty
      let isLoading = tracksVM.dataState.isLoading
      let errorText = tracksVM.dataState.errorText
      
      trackAddRow(
        tracksVM: tracksVM,
        hasTracks: hasTracks,
        isLoading: isLoading,
        errorText: errorText
      )
      .task {
        await tracksVM.onAppear()
      }
      
      if isLoading {
        loadingRow()
      } else if let errorText {
        errorRow(errorText)
      } else {
        trackRows(tracks, tracksVM: tracksVM)
      }
    }
  }
  
  // MARK: - 곡 추가 row (카드 top)
  private func trackAddRow(
    tracksVM: TracksListViewModel,
    hasTracks: Bool,
    isLoading: Bool,
    errorText: String?
  ) -> some View {
    ZStack {
      Color.fillNormal
      
      TrackAddButtonRow(
        isEmptyTracks: !hasTracks && !isLoading && errorText == nil
      ) {
        tracksVM.alertState.presentingCreateTrackSheet = true
      }
      .padding(.top, 9)
      .padding([.horizontal, .bottom], 8)
    }
    .listRowInsets(.init(top: 0, leading: 40, bottom: 0, trailing: 22))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 15,
        bottomLeadingRadius: (hasTracks || isLoading || errorText != nil) ? 0 : 15,
        bottomTrailingRadius: (hasTracks || isLoading || errorText != nil) ? 0 : 15,
        topTrailingRadius: 15
      )
    )
  }
  
  // MARK: - 로딩 row
  private func loadingRow() -> some View {
    ZStack {
      Color.fillNormal
      LoadingSpinner()
        .frame(width: 28, height: 28)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    .listRowInsets(.init(top: 0, leading: 40, bottom: 0, trailing: 22))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 0,
        bottomLeadingRadius: 15,
        bottomTrailingRadius: 15,
        topTrailingRadius: 0
      )
    )
  }
  
  // MARK: - 에러 row
  private func errorRow(_ errorText: String) -> some View {
    ZStack {
      Color.fillNormal
      
      Text(errorText)
        .font(.footnote)
        .foregroundStyle(Color.accentRedNormal)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    .listRowInsets(.init(top: 0, leading: 40, bottom: 0, trailing: 22))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 0,
        bottomLeadingRadius: 15,
        bottomTrailingRadius: 15,
        topTrailingRadius: 0
      )
    )
  }
  
  // MARK: - 정상 트랙 목록 row들
  @ViewBuilder
  private func trackRows(
    _ tracks: [Tracks],
    tracksVM: TracksListViewModel
  ) -> some View {
    ForEach(Array(tracks.enumerated()), id: \.element.tracksId) { index, track in
      trackRow(
        track,
        index: index,
        totalCount: tracks.count,
        tracksVM: tracksVM
      )
    }
  }
  
  // MARK: - 트랙 개별 row
  private func trackRow(
    _ track: Tracks,
    index: Int,
    totalCount: Int,
    tracksVM: TracksListViewModel
  ) -> some View {
    let isLast = index == totalCount - 1
    
    return ZStack {
      Color.fillNormal
      
      TrackRow(
        viewModel: projectListViewModel,
        track: track,
        rowState: tracksVM.perRowState(for: track.tracksId),
        deleteAction: {
          tracksVM.requestDelete(track: track)
        },
        editAction: {
          guard canCurrentUserEdit(track: track) else {
            failEditTrack = true
            return
          }
          tracksVM.startEditing(track: track)
        },
        rowTapAction: {
          Task {
            let section = try await tracksVM.fetchSection(tracks: track)
            guard let first = section.first else { return }
            
            print("track.tracksId.uuidString: \(track.tracksId.uuidString)")
            print("first.sectionId: \(first.sectionId,)")
            print("track.trackName: \(track.trackName)")
            
            router.push(to: .video(.list(
              tracksId: track.tracksId.uuidString,
              sectionId: first.sectionId,
              trackName: track.trackName
            )))
          }
        },
        editText: Binding(
          get: {
            (tracksVM.editingState.editingId == track.tracksId)
            ? tracksVM.editingState.editText
            : track.trackName
          },
          set: { newValue in
            if tracksVM.editingState.editingId == track.tracksId {
              tracksVM.editingState.editText = newValue
            }
          }
        ),
        canEdit: true,
        showToastMessage: $projectListViewModel.presentationState.showNameLengthTrackToast
      )
      .padding(.horizontal, 16)
      .padding(.bottom, isLast ? 8 : 0)
    }
    .listRowInsets(.init(top: 0, leading: 40, bottom: 0, trailing: 22))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 0,
        bottomLeadingRadius: isLast ? 15 : 0,
        bottomTrailingRadius: isLast ? 15 : 0,
        topTrailingRadius: 0
      )
    )
    .conditionalSwipeActions(
      enabled: tracksVM.editingState.rowState == .viewing
      && projectListViewModel.editingState.rowState == .viewing,
      edge: .trailing,
      allowsFullSwipe: false
    ) {
      Button(role: .destructive) {
        tracksVM.requestDelete(track: track)
      } label: {
        Label("삭제", systemImage: "trash.fill")
      }
      
      Button {
        guard canCurrentUserEdit(track: track) else {
          failEditTrack = true
          return
        }
        tracksVM.startEditing(track: track)
      } label: {
        Label("수정", systemImage: "pencil")
      }
    }
  }
}
