//
//  ContentView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI


struct HomeView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel: HomeViewModel = .init()
    
    @State private var teamspaceState: TeamspaceRoute?
    @State private var projectState: ProjectState = .none
    
    
    
    @State private var loadTeamspaces: [Teamspace] = []
    @State private var loadProjects: [Project] = []
    
    @State private var didInitialize: Bool = false // 첫 설정 여부
    @State private var isLoading: Bool = false
    
    
    // MARK: - 프로젝트 관련 변수
    @State private var projectRowState: ProjectRowState = .viewing
    
    // FIXME: - 변수 통합하기
    @State private var presentingRemovalSheetProject: Project?
    @State private var editSelectedProject: Project?
    @State private var choiceSelectedProject: Project?
    
    @State private var editingProjectID: UUID? = nil
    @State private var editText: String = ""
    
    
    @State private var expandedProjectIDs: Set<UUID> = []  // 펼쳐져 있는 프로젝트
    @State private var tracksByProject: [UUID: [Tracks]] = [:]  // 프로젝트별 트랙 캐시
    @State private var tracksLoading: Set<UUID> = []  // 로딩 중인 프로젝트
    @State private var tracksError: [UUID: String] = [:] // 에러 메시지
    
    
    // 버튼 위쪽 어딘가(동일 스코프)에 추가
    private var shouldDisablePrimaryButton: Bool {
        if case .editing(.update) = projectRowState {
            return editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    @State private var showCreateTracksView: Bool = false
    
    
    // MARK: - 곡 관련 변수
    @State private var tracksRowState: TracksRowState = .viewing
    @State private var editingTracksID: UUID? = nil
    @State private var presentingRemovalSheetTracks: Tracks?
    @State private var editSelectedTracks: Tracks?
    @State private var choiceSelectedTracks: Tracks?
    
    // 트랙 전용 입력 버퍼 (프로젝트의 editText와 분리!)
    @State private var trackEditText: String = ""
    
    // 트랙 완료 버튼 비활성화 조건
    private var shouldDisablePrimaryTracksButton: Bool {
        if case .editing(.update) = tracksRowState {
            return trackEditText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    
    
    var body: some View {
        ZStack {
            Color.white // FIXME: - 컬러 수정
            
            VStack {
                topTitleView
                middleProjectListView
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .overlay { if isLoading { LoadingView() } }
        .overlay(alignment: .bottomTrailing) {
            if !self.loadTeamspaces.isEmpty {
                
                // FIXME: - 버튼 적절한 분기처리
                if self.choiceSelectedProject == nil {
                    Button {
                        router.push(to: .project(.create))
                    } label: {
                        if self.loadProjects.isEmpty {
                            // TODO: 플로팅 버튼 분기 처리하기
                            HStack(spacing: 4) {
                                Text("프로젝트 추가")
                                    .font(Font.system(size: 15, weight: .medium)) // FIXME: - 폰트 수정
                                    .foregroundStyle(Color.white) // FIXME: - 컬러 수정
                                Image(systemName: "plus") // FIXME: - 이미지 수정
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16) // FIXME: - 크기 수정 ( geometry 고려 )
                                    .foregroundStyle(Color.white)// FIXME: - 컬러 수정
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.blue)
                            )
                        } else {
                            Circle()
                                .fill(Color.blue) // FIXME: - 컬러 수정
                                .frame(width: 50, height: 50) // FIXME: - 고정 크기 수정?
                                .overlay {
                                    Image(systemName: "plus")
                                        .foregroundStyle(Color.white) // FIXME: - 컬러 수정
                                        .frame(width: 20, height: 21)
                                }
                        }
                    }
                    .padding([.trailing, .bottom], 16)
                } else {
                    Button {
                        self.showCreateTracksView = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("곡 추가")
                                .font(Font.system(size: 15, weight: .medium)) // FIXME: - 폰트 수정
                                .foregroundStyle(Color.white) // FIXME: - 컬러 수정
                            Image(systemName: "music.note") // FIXME: - 이미지 수정
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16) // FIXME: - 크기 수정 ( geometry 고려 )
                                .foregroundStyle(Color.white)// FIXME: - 컬러 수정
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.blue)
                        )
                    }
                    .padding([.trailing, .bottom], 16)
                }
            }
            
            // TODO: 애니메이션 플로팅버튼 enum 분기처리 구현 때 추가하기
            
        }
        .task {
            var userTeamspaces: [UserTeamspace] = []
            
            self.isLoading = true
            defer { isLoading = false }
            
            userTeamspaces =  await viewModel.fetchUserTeamspace(userId: MockData.userId) // FIXME: - 유저 아이디 교체
            self.teamspaceState = userTeamspaces.isEmpty ? .create : .list
            self.loadTeamspaces =  await viewModel.fetchTeamspaces(userTeamspaces: userTeamspaces)
            
            switch didInitialize {
            case false: // FIXME: - 배열의 첫 번째 요소를 currentTeamspace로 설정 => 추후 마지막 접속 스페이스를 설정할지 논의
                if let firstTeamspace = loadTeamspaces.first {
                    self.viewModel.fetchCurrentTeamspace(teamspace: firstTeamspace)
                    
                }
                self.didInitialize = true
            case true:
                break
            }
            
            self.loadProjects = await viewModel.fetchCurrentTeamspaceProject()
            switch self.loadProjects.isEmpty {
            case true:
                self.projectState = .none
            case false:
                self.projectState = .list
            }
        }
    }
    
    // MARK: - 탑 타이틟 뷰 (팀 스페이스 + 설정 아이콘)
    private var topTitleView: some View {
        HStack {
            switch teamspaceState {
            case .none, .create:
                Button {
                    router.push(to: .teamspace(.create))
                } label: {
                    Text("팀 스페이스를 생성해주세요>")
                        .font(Font.title3) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
            case .list, .setting:
                Button {
                    router.push(to: .teamspace(.list))
                } label: {
                    Text(viewModel.currentTeamspace?.teamspaceName ?? "")
                        .font(Font.title3) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
            }
            Spacer()
            switch teamspaceState {
            case .none, .create:
                EmptyView()
            case .list, .setting:
                Button {
                    router.push(to: .teamspace(.setting))
                } label: {
                    Image(systemName: "person.2.badge.gearshape.fill") // FIXME: - 이미지 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
            }
        }
    }
    
    
    // MARK: - ProjectRowState 조금 더 편안한게 변경하는 로직
    private func rowState(for projectID: UUID) -> ProjectRowState {
        switch projectRowState {
        case .viewing:
            return .viewing
        case .editing(.none):
            return .editing(.none)   // 편집모드 진입 직후 (삭제/수정 버튼 노출)
        case .editing(.delete):
            return .editing(.delete)
        case .editing(.update):
            return (editingProjectID == projectID) ? .editing(.update) : .editing(.none)
        }
    }
    
    
    // MARK: - 해당 프로젝트의 곡을 뷰에 나타내는 로직
    private func toggleExpand(for project: Project) {
        let id = project.projectId
        
        if expandedProjectIDs.contains(id) {
            expandedProjectIDs.removeAll()
            choiceSelectedProject = nil
            return
        }
        
        // 다른 프로젝트 탭하면 → 기존 모두 접고 이거 하나만 펼치기
        expandedProjectIDs = [id]
        choiceSelectedProject = project
        
        // 캐시가 있으면 재조회 생략
        if tracksByProject[id] != nil { return }
        
        tracksLoading.insert(id)
        tracksError[id] = nil
        Task {
            let tracks = try await viewModel.fetchTracks(projectId: id.uuidString)
            await MainActor.run {
                tracksByProject[id] = tracks
                tracksLoading.remove(id)
            }
        }
    }
    
    
    
    // MARK: - 미들 프로젝트 리스트 뷰
    private var middleProjectListView: some View {
        VStack {
            switch projectState {
            case .none:
                Text("프로젝트가 없습니다.")
                    .font(Font.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.gray)
            case .list:
                LabeledContent {
                    // 곡 리스트가 보이지 않는 상태
                    if self.choiceSelectedProject == nil {
                        // =========================
                        // 프로젝트 편집 헤더 버튼
                        // =========================
                        HStack(spacing: 16) {
                            if let sec = projectRowState.secondaryTitle {
                                Button(sec) {
                                    projectRowState = .viewing
                                    editingProjectID = nil
                                    editSelectedProject = nil
                                    editText = ""
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(projectRowState.secondaryColor)
                            }
                            
                            Button(projectRowState.primaryTitle) {
                                switch projectRowState {
                                case .viewing:
                                    projectRowState = .editing(.none)
                                    editSelectedProject = nil
                                    editText = ""
                                case .editing(.none), .editing(.delete):
                                    projectRowState = .viewing
                                    editSelectedProject = nil
                                    editText = ""
                                case .editing(.update):
                                    Task {
                                        guard let id = editingProjectID?.uuidString else {
                                            projectRowState = .viewing
                                            return
                                        }
                                        try await viewModel.updateProjectName(projectId: id, newProjectName: editText)
                                        self.loadProjects = await self.viewModel.fetchCurrentTeamspaceProject()
                                        projectRowState = .viewing
                                        editingProjectID = nil
                                        editSelectedProject = nil
                                        editText = ""
                                    }
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(projectRowState.primaryColor)
                            .disabled(shouldDisablePrimaryButton)
                            .opacity(shouldDisablePrimaryButton ? 0.5 : 1.0)
                        }
                        
                    } else {
                        // 곡 리스트가 보이는 상태
                        // =========================
                        // 트랙 편집 헤더 버튼
                        // =========================
                        HStack(spacing: 16) {
                            if let sec = tracksRowState.secondaryTitle {
                                Button(sec) {
                                    tracksRowState = .viewing
                                    editingTracksID = nil
                                    editSelectedTracks = nil
                                    trackEditText = ""
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(tracksRowState.secondaryColor)
                            }
                            
                            Button(tracksRowState.primaryTitle) {
                                switch tracksRowState {
                                case .viewing:
                                    tracksRowState = .editing(.none)
                                    editSelectedTracks = nil
                                    trackEditText = ""
                                case .editing(.none), .editing(.delete):
                                    tracksRowState = .viewing
                                    editSelectedTracks = nil
                                    trackEditText = ""
                                case .editing(.update):
                                    Task {
                                        guard let trackId = editingTracksID?.uuidString else {
                                            tracksRowState = .viewing
                                            return
                                        }
                                        try await viewModel.updateTracksName(
                                            tracksId: trackId,
                                            newTracksName: trackEditText
                                        )
                                        
                                        // 프로젝트 목록 전체가 아니라, 현재 펼친 프로젝트 트랙만 갱신
                                        let (id, tracks) = try await viewModel.refreshTracksForSelectedProject(
                                            choiceSelectedProject: self.choiceSelectedProject
                                        )
                                        // UI 변경 메인 쓰레드에서 진행
                                        await MainActor.run {
                                            tracksByProject[id] = tracks
                                            tracksError[id] = nil
                                        }
                                        
                                        tracksRowState = .viewing
                                        editingTracksID = nil
                                        editSelectedTracks = nil
                                        trackEditText = ""
                                    }
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tracksRowState.primaryColor)
                            .disabled(shouldDisablePrimaryTracksButton)
                            .opacity(shouldDisablePrimaryTracksButton ? 0.5 : 1.0)
                        }
                    }
                } label: {
                    Text(self.choiceSelectedProject == nil ? "프로젝트 목록" : (choiceSelectedProject?.projectName ?? "프로젝트 목록"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.gray)
                }
                
                List(self.loadProjects, id: \.projectId) { project in
                    VStack(spacing: 8) {
                        ListCell(
                            title: project.projectName,
                            projectRowState: rowState(for: project.projectId),
                            deleteAction: { presentingRemovalSheetProject = project },
                            editAction: {
                                editText         = project.projectName
                                editSelectedProject  = project
                                editingProjectID = project.projectId
                                projectRowState  = .editing(.update)
                            },
                            rowTapAction: { toggleExpand(for: project) },
                            editText: Binding(
                                get: { (editingProjectID == project.projectId) ? editText : project.projectName },
                                set: { if editingProjectID == project.projectId { editText = $0 } }
                            ),
                            isExpanded: expandedProjectIDs.contains(project.projectId) // 화살표 이미지 회전
                        )
                        .listRowSeparator(.hidden)
                        
                        
                        if expandedProjectIDs.contains(project.projectId) {
                            if tracksLoading.contains(project.projectId) {
                                HStack {
                                    ProgressView()
                                    Text("트랙 불러오는 중…").font(.system(size: 14)).foregroundStyle(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                            } else if let error = tracksError[project.projectId] {
                                Text("불러오기 실패: \(error)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 20)
                            } else {
                                let tracks = tracksByProject[project.projectId] ?? []
                                VStack(spacing: 10) {
                                    if tracks.isEmpty {
                                        Text("곡이 없습니다. 추가해보세요")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.gray.opacity(0.1)) // FIXME: - 컬러 수정
                                            )
                                    } else {
                                        ForEach(tracks, id: \.trackId) { track in
                                            TrackRow(
                                                track: track,
                                                rowState: (tracksRowState == .editing(.update) && editingTracksID == track.trackId)
                                                ? .editing(.update)
                                                : (tracksRowState == .viewing ? .viewing : .editing(.none)),
                                                deleteAction: {
                                                    // 삭제 후 현재 프로젝트 트랙만 새로고침
                                                    //                                                    Task {
                                                    //                                                        try await viewModel.deleteTrack(trackId: track.trackId.uuidString)
                                                    //                                                        await refreshTracksForSelectedProject()
                                                    //                                                    }
                                                },
                                                editAction: {
                                                    trackEditText      = track.trackName
                                                    editSelectedTracks = track
                                                    editingTracksID    = track.trackId
                                                    tracksRowState     = .editing(.update)
                                                },
                                                rowTapAction: {
                                                    // TODO: 카단 뷰(트랙들)와 연결 지점
                                                },
                                                editText: Binding(
                                                    get: { (editingTracksID == track.trackId) ? trackEditText : track.trackName },
                                                    set: { if editingTracksID == track.trackId { trackEditText = $0 } }
                                                )
                                            )
                                        }
                                    }
                                }
                                .padding(.leading, 20)
                            }
                        }
                    }
                    .animation(.easeInOut, value: expandedProjectIDs)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $presentingRemovalSheetProject) { project in
            BottomConfirmSheetView(
                titleText: "\(project.projectName)\n프로젝트의 내용이 모두 삭제됩니다.\n 계속하시겠어요?",
                primaryText: "모두 삭제") {
                    Task {
                        try await viewModel.removeProject(projectId: project.projectId.uuidString)
                        self.loadProjects = await self.viewModel.fetchCurrentTeamspaceProject() // 프로젝트 리로드
                    }
                }
        }
        .sheet(isPresented: $showCreateTracksView) {
            // TODO: 컴포넌트화 만들기
            CreateTracksView(choiceSelectedProject: $choiceSelectedProject,
                             onCreated: {
                guard let project = choiceSelectedProject else { return }
                let id = project.projectId
                
                tracksByProject[id] = nil
                tracksLoading.insert(id)
                tracksError[id] = nil
                
                Task {
                    let tracks = try await viewModel.fetchTracks(projectId: id.uuidString)
                    await MainActor.run {
                        tracksByProject[id] = tracks
                        tracksLoading.remove(id)
                    }
                }
            }
            )
            .presentationDetents([.fraction(0.9)])
            .presentationCornerRadius(16)
        }
    }
}


//#Preview {
//    NavigationStack {
//        HomeView()
//            .environmentObject(NavigationRouter())
//    }
//}
//
