//
//  TeamspaceSettingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import SwiftUI

struct TeamspaceSettingView: View {
    
    @EnvironmentObject private var rotuer: NavigationRouter
    
    @State private var viewModel: TeamspaceSettingViewModel = .init()
    @State private var editingState: EditingState = .viewing
    @State private var teamspaceRole: TeamspaceRole = .viewer
    @State private var memberListMode: MemberListMode = .browsing
    
    @State private var users: [User] = [] // 유저 정보
    
    @State private var isPresentingTeamspaceDeletionSheet: Bool = false // 팀 스페이스 삭제 시트 제어
    @State private var presentingMemberRemovalSheetUser: User?  // 팀원 방출 시트 변수
    
    // 수정하기 변수
    @State private var editedName: String = ""
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color.white // FIXME: - 컬러 수정
            
            VStack {
                topTeamspaceSettingView.padding(.horizontal, 16)
                Spacer().frame(height: 32)
                Divider()
                Spacer().frame(height: 32)
                middleTeamMemberManagementView
                Spacer()
                bottomDeleteTeamspaceView.padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $isPresentingTeamspaceDeletionSheet) {
            switch teamspaceRole {
            case .viewer:
                BottomConfirmSheetView(
                    titleText: "\(viewModel.currentTeamspace?.teamspaceName ?? "")\n팀스페이스를 나가시겠어요?",
                    primaryText: "팀 스페이스 나가기") {
                        Task {
                            try await viewModel.leaveTeamspace()
                            
                        }
                    }
            case .owner:
                BottomConfirmSheetView(
                    titleText: "\(viewModel.currentTeamspace?.teamspaceName ?? "")\n팀스페이스를 삭제하시겠어요?",
                    primaryText: "팀 스페이스 삭제") {
                        Task {
                            try await viewModel.removeTeamspaceAndDetachFromAllUsers() // FIXME: - 로직 수정
                            await MainActor.run { rotuer.pop() }
                        }
                    }
            }
        }
        .sheet(item: $presentingMemberRemovalSheetUser) { selectedUser in
            BottomConfirmSheetView(
                titleText: "\(selectedUser.name)\n팀 멤버를 내보내시겠어요?",
                primaryText: "내보내기") {
                    Task {
                        let users: [User] = try await viewModel.removeTeamMemberAndReload(userId: selectedUser.userId.uuidString)
                        await MainActor.run {
                            self.users = users
                            self.presentingMemberRemovalSheetUser = nil
                        }
                    }
                }
        }
        .toolbar {
            ToolbarLeadingBackButton()
            ToolbarCenterTitle(text: "팀 스페이스 설정")
        }
        .task(id: viewModel.currentTeamspace?.teamspaceId) {
            // 로그인 유저와 팀 스페이스 ownerId가 일치하면 발생하는 로직 => 팀 스페이스 주인 => 권한 up
            await MainActor.run { self.teamspaceRole = viewModel.isTeamspaceOwner() ? .owner : .viewer }
            do {
                let users: [User] = try await viewModel.fetchCurrentTeamspaceAllMember()
                self.users = users
            } catch {
                print("error: \(error.localizedDescription)")
            }
            
        }
    }
    
    // MARK: - 탑 팀 스페이스 설정 뷰 (팀 이름 수정하기 + 팀 멤버 초대하기)
    private var topTeamspaceSettingView: some View {
        VStack(alignment: .leading) {
            LabeledContent {
                switch teamspaceRole {
                case .viewer:
                    EmptyView()
                case .owner:
                    switch editingState {
                    case .viewing:
                        UpdateButton(
                            title: "수정하기",
                            titleColor: Color.gray) { // FIXME: - 컬러 수정
                                self.editedName = viewModel.currentTeamspace?.teamspaceName ?? ""
                                self.editingState = .editing
                                self.nameFieldFocused = true
                            }
                    case .editing:
                        UpdateButton(
                            title: "완료",
                            titleColor: Color.blue) { // FIXME: - 컬러 수정
                                Task {
                                    try await viewModel.renameCurrentTeamspaceAndReload(editedName: self.editedName)
                                    await MainActor.run {
                                        self.editingState = .viewing
                                        self.nameFieldFocused = false
                                    }
                                }
                            }
                            .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            } label: {
                Text("팀 이름")
                    .font(Font.system(size: 16, weight: .semibold)) // FIXME: - 폰트 수정
                    .foregroundStyle(Color.gray) // FIXME: - 컬러 수정
            }
            Spacer().frame(height: 16)
            switch editingState {
            case .viewing:
                Text(viewModel.currentTeamspace?.teamspaceName ?? "")
                    .font(.system(size: 22, weight: .medium)) // FIXME: - 폰트 수정
                    .foregroundStyle(.black) // FIXME: - 컬러 수정
            case .editing:
                TextField("팀 이름을 입력하세요", text: $editedName)
                    .font(.system(size: 22, weight: .medium)) // FIXME: - 폰트 수정
                    .foregroundStyle(.black) // FIXME: - 컬러 수정
                    .focused($nameFieldFocused)
                    .submitLabel(.return)
                    .onSubmit {
                        Task {
                            try await viewModel.renameCurrentTeamspaceAndReload(editedName: self.editedName)
                            await MainActor.run {
                                self.editingState = .viewing
                                self.nameFieldFocused = false
                            }
                        }
                    }
            }
            Spacer().frame(height: 32)
            ActionButton(
                title: "팀에 멤버 초대하기",
                color: self.editingState == .viewing ? Color.blue : Color.mint, // FIXME: - 컬러 수정
                height: 47,
                isEnabled: self.editingState == .viewing ? true : false,
                action: {
                    switch self.editingState {
                    case .viewing: // 팀원 초대하기
                        print("팀원 초대하기")
                    case .editing: // 버튼 비활성화
                        break
                    }
                }
            )
        }
    }
    
    // MARK: - 미들 팀 멤버 관리 뷰
    private var middleTeamMemberManagementView: some View {
        VStack {
            LabeledContent {
                switch teamspaceRole {
                case .viewer:
                    EmptyView()
                case .owner:
                    switch memberListMode {
                    case .browsing:
                        UpdateButton(
                            title: "팀원 삭제",
                            titleColor: Color.red) { // FIXME: - 컬러 수정
                                self.memberListMode = .removing
                            }
                    case .removing:
                        UpdateButton(
                            title: "완료",
                            titleColor: Color.blue) { // FIXME: - 컬러 수정
                                self.memberListMode = .browsing
                            }
                    }
                }
            } label: {
                Text("팀 멤버")
                    .font(Font.caption) // FIXME: - 폰트 수정
                    .foregroundStyle(Color.gray) // FIXME: - 컬러 수정
            }
            .padding(.horizontal, 16)
            List(users, id: \.userId) { user in
                LabeledContent {
                    switch memberListMode {
                    case .browsing:
                        EmptyView()
                    case .removing:
                        // 유저 멤버 중 팀스페이스 주인 아이디와 일치하면 이미지 x
                        if viewModel.currentTeamspace?.ownerId == user.userId.uuidString { EmptyView() }
                        else { MinusCircleButton { self.presentingMemberRemovalSheetUser = user } }
                    }
                } label: {
                    Text(user.name)
                        .font(Font.system(size: 16, weight: .medium)) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
            }
            .listStyle(.plain)
        }
    }
    
    // MARK: - 바텀 팀 스페이스 삭제하기 뷰
    private var bottomDeleteTeamspaceView: some View {
        VStack {
            switch teamspaceRole {
            case .viewer:
                ActionButton(
                    title: "팀 스페이스 나가기",
                    color: Color.blue, // FIXME: - 컬러 수정
                    height: 47) {
                        withAnimation(.easeInOut) { self.isPresentingTeamspaceDeletionSheet = true }
                    }
            case .owner:
                ActionButton(
                    title: "팀 스페이스 삭제하기",
                    color: Color.blue, // FIXME: - 컬러 수정
                    height: 47) {
                        withAnimation(.easeInOut) { self.isPresentingTeamspaceDeletionSheet = true }
                    }
            }
        }
    }
}


//#Preview {
//    NavigationStack {
//        TeamspaceSettingView()
//            .environmentObject(NavigationRouter())
//    }
//}
 

