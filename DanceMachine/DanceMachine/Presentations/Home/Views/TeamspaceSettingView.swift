//
//  TeamspaceSettingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import SwiftUI

// TODO: 방장과 팀원과의 보여지는 뷰 분기처리 만들기

struct TeamspaceSettingView: View {
    
    @EnvironmentObject private var rotuer: NavigationRouter
    
    @State private var viewModel: TeamspaceSettingViewModel = .init()
    @State private var editingState: EditingState = .viewing
    
    @State private var users: [User] = [] // 유저 정보
    
    @State private var isPresentingTeamspaceDeletionSheet: Bool = false // 팀 스페이스 삭제 시트 제어
    @State private var isPresentingMemberRemovalSheet: Bool = false // 팀원 방출 시트 제어
    
    // 수정하기 변수
    @State private var editedName: String = ""
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color.white // FIXME: - 컬러 수정
            
            VStack {
                topTeamspaceSettingView
                    .padding(.horizontal, 16)
                Spacer().frame(height: 32)
                Divider()
                Spacer().frame(height: 32)
                middleTeamMemberManagementView
                Spacer()
                bottomDeleteTeamspaceView
                    .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $isPresentingTeamspaceDeletionSheet) {
            
            BottomConfirmSheet(
                titleText: "\(FirebaseAuthManager.shared.currentTeamspace?.teamspaceName ?? "")\n팀스페이스를 삭제하시겠어요?",
                primaryText: "팀 스페이스 삭제"
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 33)
            .presentationDetents([.fraction(0.4)])
            .presentationCornerRadius(16)
            
        }
        .sheet(isPresented: $isPresentingMemberRemovalSheet) {
            BottomConfirmSheet(
                titleText: "\n팀 멤버를 내보내시겠어요?",
                primaryText: "내보내기"
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 33)
            .presentationDetents([.fraction(0.4)])
            .presentationCornerRadius(16)
        }
        .toolbar {
            ToolbarLeadingBackButton()
            ToolbarCenterTitle(text: "팀 스페이스 설정")
        }
        .task {
            do {
//                viewModel.teamspaceName = FirebaseAuthManager.shared.currentTeamspace?.teamspaceName ?? "" // 팀 스페이스 이름 설정
                
                let members: [Members] = try await viewModel.fetchTeamspaceMembers(
                    teamspaceId: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? ""
                )
                var userIds: [String] = []
                
                for member in members {
                    userIds.append(member.userId)
                }
                // 팀 스페이스 유저 리스트 패치
                self.users = try await viewModel.fetchUserNamesInOrder(userIds: userIds)
            } catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 탑 팀 스페이스 설정 뷰 (팀 이름 수정하기 + 팀 멤버 초대하기)
    private var topTeamspaceSettingView: some View {
        VStack(alignment: .leading) {
            LabeledContent {
                switch editingState {
                case .viewing:
                    Button("수정하기") {
                        self.editedName = FirebaseAuthManager.shared.currentTeamspace?.teamspaceName ?? ""
                        self.editingState = .editing
                        self.nameFieldFocused = true
                    }
                    .font(.caption)  // FIXME: - 폰트 수정
                    .foregroundStyle(.gray) // FIXME: - 컬러 수정
                case .editing:
                    Button("완료") {
                        Task { @MainActor in
                            do {
                                try await viewModel.updateTeamspaceName(
                                    teamspaceId: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
                                    newTeamspaceName: editedName
                                )
                                
                                // 조회 후 값 다시 넣어주기
                                FirebaseAuthManager.shared.currentTeamspace = try await FirestoreManager.shared.get(
                                    FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
                                    from: .teamspace
                                )
                                
                                self.editingState = .viewing
                                self.nameFieldFocused = false
                            } catch {
                                print("error:\(error.localizedDescription)")
                            }
                        }
                    }
                    .font(.caption) // FIXME: - 폰트 수정
                    .foregroundStyle(.blue) // FIXME: - 컬러 수정
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } label: {
                Text("팀 이름")
                    .font(Font.caption) // FIXME: - 폰트 수정
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
                        Task { @MainActor in
                            
                            try await viewModel.updateTeamspaceName(
                                teamspaceId: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
                                newTeamspaceName: editedName
                            )
                            
                            // 조회 후 값 다시 넣어주기
                            let teamspace: Teamspace = try await FirestoreManager.shared.get(
                                FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
                                from: .teamspace
                            )
                            
                            viewModel.fetchCurrentTeamspace(teamspace: teamspace)
                            
                            self.editingState = .viewing
                            nameFieldFocused = false
                        }
                    }
            }
            
            Spacer().frame(height: 32)
            
            Button {
                print("팀에 멤버 초대하기") // TODO: 기능 추가
            } label: {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.blue) // FIXME: - 컬러 수정
                    .overlay {
                        Text("팀에 멤버 초대하기")
                            .font(Font.body)
                            .foregroundStyle(Color.white)
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 47)
        }
    }
    
    // MARK: - 미들 팀 멤버 관리 뷰
    private var middleTeamMemberManagementView: some View {
        VStack {
            LabeledContent {
                Button {
                    print("팀원 삭제") // TODO: 기능 추가
                } label: {
                    Text("팀원 삭제")
                        .font(Font.caption) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.red) // FIXME: - 컬러 수정
                }
            } label: {
                Text("팀 멤버")
                    .font(Font.caption) // FIXME: - 폰트 수정
                    .foregroundStyle(Color.gray) // FIXME: - 컬러 수정
            }
            .padding(.horizontal, 16)
            
            List(users, id: \.userId) { user in
                LabeledContent {
                    Button {
                        
                    } label: {
                        Image(.minusCircle) // FIXME: - 이미지 수정 (임시)
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
            Button {
                withAnimation(.easeInOut) { isPresentingTeamspaceDeletionSheet = true }
            } label: {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.blue) // FIXME: - 컬러 수정
                    .overlay {
                        Text("팀 스페이스 삭제하기")
                            .font(Font.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.red)
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 47) // FIXME: - 임의 설정 (추후 설정)
        }
    }
    
}

#Preview {
    NavigationStack {
        TeamspaceSettingView()
            .environmentObject(NavigationRouter())
    }
}
 
