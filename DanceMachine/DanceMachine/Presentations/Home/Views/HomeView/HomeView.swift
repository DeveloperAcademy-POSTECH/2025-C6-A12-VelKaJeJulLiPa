//
//  ContentView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseAuth


struct HomeView: View {
  
  @EnvironmentObject private var router: MainRouter
  @EnvironmentObject private var inviteRouter: InviteRouter
  
  @State private var viewModel: HomeViewModel
  
  init(previewVM: HomeViewModel? = nil) {
    _viewModel = State(initialValue: previewVM ?? HomeViewModel())
  }
  
  // 시트/로딩 등 화면 로컬 상태만 유지
  @State private var presentingRemovalProject: Project?
  @State private var presentingRemovalTracks: Tracks?
  @State private var showCreateTracksView = false
  @State private var isLoading = false
  
  @State private var presentingCreateTeamspaceSheet: Bool = false
  @State private var presentingRemovalProjectAlert: Bool = false
  @State private var presentingRemovalTracksAlert: Bool = false
  @State private var presentingCreateProjectSheet: Bool = false
  
  @State private var showToastMessage: Bool = false
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea() // FIXME: - 컬러 수정
      VStack {
        if viewModel.project.rowState == .viewing && viewModel.tracks.rowState == .viewing {
          TeamspaceTitleView(
            viewModel: viewModel,
            teamspaceState: viewModel.tsBinding(\.state),
            presentingCreateTeamspaceSheet: $presentingCreateTeamspaceSheet // 팀 스페이스 생성 시트 제어
          )
          .padding(.horizontal, 16)
        }
        
        // 팀 스페이스 비어져있을 시,
        if viewModel.userTeamspaces == [] {
          VStack {
            Spacer()
            Image(systemName: "scribble")
              .font(.system(size: 110))
              .foregroundStyle(Color.fillAlternative)
              .frame(maxWidth: .infinity)
            Spacer().frame(height: 10)
            Text("팀 스페이스가 없습니다.")
              .font(.headline2Medium)
              .foregroundStyle(Color.labelAssitive)
            Spacer()
          }
        } else {
          ProjectListView(
            viewModel: viewModel,
            labelText: viewModel.plBinding(\.headerTitle),
            projects: viewModel.plBinding(\.projects),
            rowState: viewModel.plBinding(\.rowState),
            editingProjectID: viewModel.plBinding(\.editingID),
            editText: viewModel.plBinding(\.editText),
            onCommitEdit: { _, _ in await viewModel.commitProjectEdit()
            },
            onDelete: { project in presentingRemovalProject = project },
            onTap: { project in viewModel.toggleExpand(project) },
            isExpanded: { project in viewModel.isExpanded(project) },
            expandedContent: { project in
              TracksInlineView(
                viewModel: viewModel,
                project: project,
                tracks: Binding(
                  get: { viewModel.tracks.byProject[project.projectId] ?? [] },
                  set: { viewModel.tracks.byProject[project.projectId] = $0 }
                ),
                rowState: viewModel.trBinding(\.rowState),
                editingTrackID: viewModel.trBinding(\.editingID),
                editingText: viewModel.trBinding(\.editText),
                isLoading: viewModel.tracks.loading.contains(project.projectId),
                errorText: viewModel.tracks.error[project.projectId],
                onCommitEdit: { _, _ in await viewModel.commitTrackEdit() },
                onDelete: { track in
                  self.presentingRemovalTracks = track
                  self.presentingRemovalTracksAlert = true
                },
                onTap: { track in
                  Task {
                    let section = try await viewModel.fetchSection(tracks: track)
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
                }
              )
            },
            // 추가 헤더 제어 파라미터
            isAnyProjectExpanded: viewModel.project.expandedID != nil,
            tracksRowState: viewModel.trBinding(\.rowState),
            isTracksPrimaryDisabled: {
              if case .editing(.update) = viewModel.tracks.rowState {
                return viewModel.tracks.editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }
              return false
            }(),
            onTracksPrimaryUpdate: { Task { await viewModel.commitTrackEdit() }},
            onTracksCancelSideEffects: {
              if case .editing(.update) = viewModel.tracks.rowState {
                // 업데이트 중이면 텍스트 유지
              } else {
                viewModel.tracks.editText = ""
              }
              viewModel.tracks.editingID = nil
            },
            showToastMessage: $showToastMessage,
            presentingRemovalProjectAlert: $presentingRemovalProjectAlert
          )
          .padding(.horizontal, 16)
        }
      }
      .animation(
        .spring(response: 0.3, dampingFraction: 0.85), // FIXME: - 애니메이션 효과 적절한지
        value: viewModel.project.rowState
      )
      .animation(
        .spring(response: 0.3, dampingFraction: 0.85), // FIXME: - 애니메이션 효과 적절한지
        value: viewModel.tracks.rowState
      )
      .toast(
        isPresented: $showToastMessage,
        duration: 2,
        position: .bottom,
        bottomPadding: 16   // 하단에서 얼마나 띄울지(버튼 위치)
      ) {
        ToastView(text: "프로젝트 이름은 20자 이내로 입력해주세요.", icon: .warning)
      }
    }
    // 프로젝트 삭제 경고
    .alert(
      "\(presentingRemovalProject?.projectName ?? "")를\n식제하시겠어요?",
      isPresented: $presentingRemovalProjectAlert
    ) {
      Button("취소", role: .cancel) {}
      Button("삭제", role: .destructive) {
        Task {
          try await viewModel.removeProject(
            projectId: presentingRemovalProject?.projectId.uuidString ?? ""
          )
          _ = await viewModel.fetchCurrentTeamspaceProject()
        }
      }
    } message: {
      Text("프로젝트 모든 내용이 삭제됩니다.")
    }
    // 곡 삭제 시트
    .alert(
      "\(presentingRemovalTracks?.trackName ?? "")를\n식제하시겠어요?",
      isPresented: $presentingRemovalTracksAlert
    ) {
      Button("취소", role: .cancel) {}
      Button("삭제", role: .destructive) {
        Task {
          try await viewModel.removeTracksAndSection(
            tracksId: self.presentingRemovalTracks?.tracksId.uuidString ?? ""
          )
          if let pid = viewModel.project.expandedID {
            viewModel.loadTracks(for: pid) // 삭제 후 갱신
          }
        }
      }
    } message: {
      Text("곡과 영상 모두 삭제됩니다.")
    }
    // 팀 스페이스 생성 시트
    .sheet(isPresented: $presentingCreateTeamspaceSheet) {
      CreateTeamspaceView(onCreated: {
        Task {
          self.isLoading = true
          defer { isLoading = false }
          await viewModel.ensureTeamspaceInitialized()
          await viewModel.fetchCurrentTeamspaceProject()
        }
      })
      .presentationDragIndicator(.visible)
      .presentationDetents([.fraction(0.9)])
      .presentationCornerRadius(16)
    }
    // 프로젝트 생성 시트
    .sheet(isPresented: $presentingCreateProjectSheet) {
      CreateProjectView(onCreated: {
        Task {
          self.isLoading = true
          defer { isLoading = false }
          let newloaded = await viewModel.fetchCurrentTeamspaceProject()
          self.viewModel.project.projects = newloaded
        }
      })
      .presentationDragIndicator(.visible)
      .presentationDetents([.fraction(0.9)])
      .presentationCornerRadius(16)
    }
    // 곡 생성 시트
    .sheet(isPresented: $showCreateTracksView) {
      // 기존 CreateTracksView API 그대로 쓴다고 가정
      CreateTracksView(
        choiceSelectedProject: Binding(
          get: { viewModel.selectedProject },
          set: { _ in } // 외부에서 바꾸지 않음(읽기 전용 바인딩)
        ),
        onCreated: { // 곡 생성 됐을 때, 로직
          if let pid = viewModel.project.expandedID {
            viewModel.loadTracks(for: pid) // 생성 후 갱신
          }
        }
      )
      .presentationDragIndicator(.visible)
      .presentationDetents([.fraction(0.9)])
      .presentationCornerRadius(16)
    }
    .overlay { if isLoading { LoadingView() } }
    .overlay(alignment: .bottomTrailing) {
      if let mode = viewModel.fabMode {
        FloatingActionButton(
          mode: mode,
          isProjectListEmpty: viewModel.isProjectListEmpty,
          onAddProject: { self.presentingCreateProjectSheet = true },
          onAddTrack: { showCreateTracksView = true }
        )
      }
    }
    .task {
      await viewModel.setupNotificationAuthorizationIfNeeded()
    }
    .task {
      if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
      guard FirebaseAuthManager.shared.user != nil else {
        print("🚫 HomeView.task 중간: 로그인 상태 아님")
        return
      }
      
      
      isLoading = true
      defer { isLoading = false }
      print("🔥 HomeViewLoding...")
      
      // TODO: 딥 링크 타고 들어올때 팀 스페이스 명을 아래 로직을 활용해서 변경해야함.
      do {
        try await viewModel.fetchUserInfo()
        await viewModel.ensureTeamspaceInitialized()
        await viewModel.fetchCurrentTeamspaceProject()
        try await NotificationManager.shared.refreshBadge(for: FirebaseAuthManager.shared.user?.uid ?? "")
      } catch {
        
      }
    }
    // 팀스페이스 바뀌면 리로드
    .onChange(of: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId) {
      Task {
        if FirebaseAuthManager.shared.currentTeamspace == nil {
          // 팀스페이스가 사라진 경우(삭제 등)
          await viewModel.handleTeamspaceDeleted()
        } else {
          // 팀스페이스가 다른 것으로 교체된 경우
          await viewModel.reloadProjectsAfterTeamspaceChange()
        }
      }
    }
  }
}

#Preview("HomeView · 프리뷰 목 데이터") {
  NavigationStack {
    HomeView(previewVM: .previewFilled())
      .environmentObject(MainRouter())
      .environmentObject(InviteRouter())
  }
}

