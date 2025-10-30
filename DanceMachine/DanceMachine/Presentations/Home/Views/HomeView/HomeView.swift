//
//  ContentView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseAuth


struct HomeView: View {

    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var inviteRouter: InviteRouter

    @State private var viewModel: HomeViewModel

    init(previewVM: HomeViewModel? = nil) {
        _viewModel = State(initialValue: previewVM ?? HomeViewModel())
    }
    
    // 시트/로딩 등 화면 로컬 상태만 유지
    @State private var presentingRemovalSheetProject: Project?
    @State private var presentingRemovalSheetTracks: Tracks?
    @State private var showCreateTracksView = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.white
            VStack {
                TeamspaceTitleView(
                    viewModel: viewModel,
                    teamspaceState: viewModel.tsBinding(\.state)
                )

                ProjectListView(
                    viewModel: viewModel,
                    labelText: viewModel.plBinding(\.headerTitle),
                    projects: viewModel.plBinding(\.projects),
                    rowState: viewModel.plBinding(\.rowState),
                    editingProjectID: viewModel.plBinding(\.editingID),
                    editText: viewModel.plBinding(\.editText),
                    onCommitEdit: { _, _ in await viewModel.commitProjectEdit() },
                    onDelete: { project in presentingRemovalSheetProject = project },
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
                            onDelete: { track in presentingRemovalSheetTracks = track },
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
                    }
                )

                Spacer()
            }
            .sheet(item: $presentingRemovalSheetProject) { project in
                BottomConfirmSheetView(
                    titleText: "\(project.projectName)\n프로젝트의 내용이 모두 삭제됩니다.\n 계속하시겠어요?",
                    primaryText: "모두 삭제"
                ) {
                    Task {
                        try await viewModel.removeProject(projectId: project.projectId.uuidString)
                        _ = await viewModel.fetchCurrentTeamspaceProject()
                    }
                }
            }
            .sheet(item: $presentingRemovalSheetTracks) { tracks in
                BottomConfirmSheetView(
                    titleText: "\(tracks.trackName)\n곡과 영상을 모두 삭제하시겠어요?",
                    primaryText: "모두 삭제"
                ) {
                    Task {
                        try await viewModel.removeTracksAndSection(tracksId: tracks.tracksId.uuidString)
                        if let pid = viewModel.project.expandedID {
                            viewModel.loadTracks(for: pid) // 삭제 후 갱신
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateTracksView) {
                // 기존 CreateTracksView API 그대로 쓴다고 가정
                CreateTracksView(
                    choiceSelectedProject: Binding(
                        get: { viewModel.selectedProject },
                        set: { _ in } // 외부에서 바꾸지 않음(읽기 전용 바인딩)
                    ),
                    onCreated: {
                        if let pid = viewModel.project.expandedID {
                            viewModel.loadTracks(for: pid) // 생성 후 갱신
                        }
                    }
                )
                .presentationDetents([.fraction(0.9)])
                .presentationCornerRadius(16)
            }
        }
        .padding(.horizontal, 16)
        .overlay { if isLoading { LoadingView() } }
        .overlay(alignment: .bottomTrailing) {
            if let mode = viewModel.fabMode {
                FloatingActionButton(
                    mode: mode,
                    isProjectListEmpty: viewModel.isProjectListEmpty,
                    onAddProject: { router.push(to: .project(.create)) },
                    onAddTrack: { showCreateTracksView = true }
                )
            }
        }
        .task {
            await viewModel.setupNotificationAuthorizationIfNeeded()
        }
        .task {
            if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
            isLoading = true
            defer { isLoading = false }
            print("🔥 HomeViewLoding...")
            
            // TODO: 딥 링크 타고 들어올때 팀 스페이스 명을 아래 로직을 활용해서 변경해야함.
            do {
                try await viewModel.fetchUserInfo()
                await viewModel.ensureTeamspaceInitialized()
                await viewModel.fetchCurrentTeamspaceProject()
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
            .environmentObject(NavigationRouter())
            .environmentObject(InviteRouter())
    }
}

