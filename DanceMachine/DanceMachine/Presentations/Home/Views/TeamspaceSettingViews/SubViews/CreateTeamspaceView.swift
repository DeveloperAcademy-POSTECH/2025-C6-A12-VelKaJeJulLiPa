//
//  CreateTeamspaceView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

struct CreateTeamspaceView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel: CreateTeamspaceViewModel = .init()
  
  // 네비게이션 / 시트 판별 변수
  private var presentationStyle: PresentationStyle
  
  // 시트용 변수
  @State private var teamspaceNameText = ""
  @State private var closeAlert: Bool = false
  @State private var isCreatingTeamspace: Bool = false
  @State private var isPresentingInviteSheet: Bool = false // 초대 화면 flow
  
  // 공용 변수
  @FocusState private var isFocusTextField: Bool
  
  var onCreated: () -> Void = {} // FIXME: - 여부 확인
  
  // 애니메이션 용도 변수 (drawOn)
  @State private var checkEffectActive: Bool = false //애니메이션 트리거 + 표시 조건

  @State var overText: Bool = false
  
  init(presentationStyle: PresentationStyle, onCreated: @escaping () -> Void = {}) {
    self.presentationStyle = presentationStyle
    self.onCreated = onCreated
  }
  
  var body: some View {
    ZStack {
      backgroundColor(style: presentationStyle).ignoresSafeArea() // 배경색 지정
      
      VStack {
        Spacer().frame(height: 29)
        if presentationStyle == .sheet {
          topTitleView
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        } else {
          EmptyView()
        }
        Spacer()
        inputTeamspaceNameView
          .padding(.horizontal, 16)
        Spacer()
        bottomButtonView
          .padding(.horizontal, 16)
      }
      .dismissKeyboardOnTap()
    }
    .fullScreenCover(isPresented: $isPresentingInviteSheet) {
      // FIXME: - 임시 네비게이션 스택 (툴 바 보여주기 위한 용도)
      NavigationStack {
        OnboardingInviteView()
      }
    }
    .toolbar {
      if presentationStyle == .navigation {
        ToolbarLeadingBackButton(icon: .chevron)
        ToolbarCenterTitle(text: "팀 스페이스 만들기")
      }
    }
    .alert(
      "변경사항이 저장되지 않았습니다.\n종료하시겠어요?",
      isPresented: $closeAlert
    ) {
      Button("취소", role: .cancel) {}
      Button("나가기", role: .destructive) { dismiss() }
    } message: {
      Text("저장하지 않은 변경사항은 사라집니다.")
    }
  }
  
  // MARK: - 탑 타이틀
  private var topTitleView: some View {
    ZStack { // TODO: 서치
      // 가운데 정렬 타이틀
      Text("팀 스페이스 만들기")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelStrong)
        .frame(maxWidth: .infinity, alignment: .center)
      
      // 왼쪽 X 버튼
      HStack {
        Image(systemName: "xmark.circle.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 44, height: 44)
          .foregroundStyle(Color.labelNormal)
          .onTapGesture { self.closeAlert = true }
        Spacer()
      }
    }
  }
  
  // MARK: - 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
  private var inputTeamspaceNameView: some View {
    VStack {
      Text("팀 스페이스 이름을 입력하세요.")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      Spacer().frame(height: 32)
      textFieldView()
      Spacer().frame(height: 16)
      textFieldItem()
    }
  }
  
  // MARK: - 바텀 팀 스페이스 만들기 뷰
  private var bottomButtonView: some View {
    ZStack {
      ActionButton(
        title: "팀 스페이스 만들기",
        color: teamspaceNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
        height: 47,
        isEnabled: !teamspaceNameText.isEmpty && !isCreatingTeamspace
      ) {
        Task {
          guard !teamspaceNameText.isEmpty else { return }
          
          isCreatingTeamspace = true
          defer {
            isCreatingTeamspace = false
            switch presentationStyle {
            case .sheet:
              dismiss()
            case .navigation:
              self.isPresentingInviteSheet = true
            }
          }
          
          try await viewModel.createTeamspaceWithInitialMembership(
            teamspaceNameText: teamspaceNameText
          )
                    
          await MainActor.run { self.checkEffectActive = true }
          try? await Task.sleep(for: .seconds(2)) // 애니메이션 2초 효과
        }
      }
      .disabled(isCreatingTeamspace)
      
      // 로딩 오버레이
      if isCreatingTeamspace {
        // 버튼 영역을 꽉 채우는 배경
        RoundedRectangle(cornerRadius: 15)
          .fill(Color.fillAssitive)
          .frame(height: 47)
        
        LoadingSpinner()
          .frame(width: 28, height: 28)
      }
      
      // 생성 완료 됐을 시, 보여지는 뷰
      completedButtonView
    }
    .padding(.bottom, 16)
  }
  
  // MARK: - 텍스트 필드 뷰
  @ViewBuilder
  private func textFieldView() -> some View {
    // 가운데 정렬 텍스트 필드 + 배경
    TextField("팀 이름", text: $teamspaceNameText)
      .font(.headline2Medium)
      .foregroundStyle(Color.labelStrong)
      .tint(Color.labelStrong)
      .multilineTextAlignment(.center)
      .onChange(of: teamspaceNameText) { oldValue, newValue in
        // 1) 삭제 방향이면 검증 로직은 태우지 않고, 경고만 정리
        if newValue.count < oldValue.count {
          // 20자 미만이면 경고 끔
          if newValue.count < 20 {
            overText = false
          }
          return
        }
        
        // 2) 입력(길이 증가)일 때만 검증
        let result = viewModel.validateTeamspaceName(
          oldValue: oldValue,
          newValue: newValue
        )
        
        // 3) 자른 텍스트 반영 (무한 onChange 방지용 체크)
        if teamspaceNameText != result.text {
          teamspaceNameText = result.text
        }
        
        // 4) 경고 플래그 반영
        overText = result.overText
      }
      .frame(maxWidth: .infinity)
      .frame(height: 51)
      .overlay(alignment: .trailing) {
        XmarkButton {
          self.teamspaceNameText = ""
        }
          .padding(.trailing, 8)
      }
      .background(
        RoundedRectangle(cornerRadius: 15)
          .fill(textFieldBackgroundColor(style: presentationStyle))
          .overlay(
            RoundedRectangle(cornerRadius: 15)
              .stroke(
                isFocusTextField ? Color.secondaryStrong : Color.clear,
                lineWidth: isFocusTextField ? 1 : 0
              )
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 15)
          .stroke(self.overText ? Color.accentRedNormal : Color.clear, lineWidth: 1)
      )
      .focused($isFocusTextField)
  }
  
  // MARK: - 텍스트 필드 아이템 (글자수 라벨, x 버튼)
  @ViewBuilder
  private func textFieldItem() -> some View {
    if self.overText == false {
      Text("\(teamspaceNameText.count)/20")
        .font(.headline2Medium)
        .foregroundStyle(Color.secondaryNormal)
    } else {
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(Color.accentRedNormal)
        .opacity(self.overText ? 1 : 0)
    }
  }
  
  // MARK: - 팀 스페이스 생성 시, 완료 뷰
  private var completedButtonView: some View {
    RoundedRectangle(cornerRadius: 15)
      .fill(Color.fillAssitive)
      .frame(height: 47)
      .opacity(checkEffectActive ? 1 : 0) // 전체 오버레이 자체를 페이드 인
      .overlay {
        HStack(spacing: 10) {
          if #available(iOS 26.0, *) {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 24, weight: .medium))
              .foregroundStyle(Color.secondaryNormal)
              .symbolEffect(
                .drawOn,
                options: .nonRepeating,
                isActive: !checkEffectActive   // 이 값이 false → true로 바뀔 때 한 번 그림
              )
          } else {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 24, weight: .medium))
              .foregroundStyle(Color.secondaryNormal)
          }
          
          Text("팀을 생성했습니다.")
            .font(.headline2SemiBold)
            .foregroundStyle(Color.secondaryNormal)
            .opacity(checkEffectActive ? 1 : 0)
        }
      }
  }
  
  // MARK: - 배경화면 색 분기처리 ( sheet / Navigation )
  private func backgroundColor(style presentationStyle: PresentationStyle) -> Color {
    switch presentationStyle {
    case .sheet:
      Color.backgroundElevated
    case .navigation:
      Color.backgroundNormal
    }
  }
  
  // MARK: - 텍스트 필드 색 분기처리 ( sheet / Navigation )
  private func textFieldBackgroundColor(style presentationStyle: PresentationStyle) -> Color {
    switch presentationStyle {
    case .sheet:
      Color.fillStrong
    case .navigation:
      Color.fillNormal
    }
  }
  
}

#Preview("시트 팀스페이스 생성 뷰") {
  NavigationStack {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      CreateTeamspaceView(
        presentationStyle: .sheet
      )
        .environmentObject(MainRouter())
    }
  }
}


#Preview("네비게이션 팀스페이스 생성 뷰") {
  NavigationStack {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      CreateTeamspaceView(
        presentationStyle: .navigation
      )
        .environmentObject(MainRouter())
    }
  }
}

