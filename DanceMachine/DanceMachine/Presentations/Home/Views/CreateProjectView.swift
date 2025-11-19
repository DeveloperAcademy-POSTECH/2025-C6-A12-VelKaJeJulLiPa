//
//  CreateProjectView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

struct CreateProjectView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel: CreateProjectViewModel = .init()
  @State private var projectNameText = ""
  
  @FocusState private var isFocusTextField: Bool
  
  @State private var closeAlert: Bool = false
  
  var onCreated: () -> Void = {}
  
  @State private var isCreatingProject: Bool = false
  @State var overText: Bool = false
  // 애니메이션 용도 변수 (drawOn)
  @State private var checkEffectActive: Bool = false //애니메이션 트리거 + 표시 조건
  
  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()
      
      VStack {
        Spacer().frame(height: 29)
        topTitleView
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
        Spacer()
        inputProjectNameView
          .padding(.horizontal, 16)
        Spacer()
        bottomButtonView
          .padding(.horizontal, 16)
      }
      .dismissKeyboardOnTap()
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
      Text("새 프로젝트 만들기")
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
  
  // MARK: - 프로젝트 텍스트 필드 뷰 ("프로젝트 이름" + 텍스트 필드)
  private var inputProjectNameView: some View {
    VStack {
      Text("프로젝트 이름을 입력하세요.")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      Spacer().frame(height: 32)
      textFieldView()
      Spacer().frame(height: 16)
      textFieldItem()
    }
  }
  
  // MARK: - 텍스트 필드 뷰
  @ViewBuilder
  private func textFieldView() -> some View {
    // 가운데 정렬 텍스트 필드 + 배경
    TextField("(예시) 대동제", text: $projectNameText)
      .font(.headline2Medium)
      .foregroundStyle(Color.labelStrong)
      .tint(Color.labelStrong)
      .multilineTextAlignment(.center)
      .onChange(of: projectNameText) { oldValue, newValue in
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
        if projectNameText != result.text {
          projectNameText = result.text
        }
        
        // 4) 경고 플래그 반영
        overText = result.overText
      }
      .frame(maxWidth: .infinity)
      .frame(height: 51)
      .overlay(alignment: .trailing) {
        XmarkButton {
          self.projectNameText = ""
        }
          .padding(.trailing, 8)
      }
      .background(
        RoundedRectangle(cornerRadius: 15)
          .fill(Color.fillStrong)
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
      Text("\(projectNameText.count)/20")
        .font(.headline2Medium)
        .foregroundStyle(Color.secondaryNormal)
    } else {
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(Color.accentRedNormal)
        .opacity(self.overText ? 1 : 0)
    }
  }
  
  // MARK: - 바텀 팀 스페이스 만들기 뷰
  private var bottomButtonView: some View {
    ZStack {
      ActionButton(
        title: "새 프로젝트 만들기",
        color: projectNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
        height: 47,
        isEnabled: !projectNameText.isEmpty && !isCreatingProject
      ) {
        Task {
          guard !projectNameText.isEmpty else { return }
          
          isCreatingProject = true
          
          defer {
            isCreatingProject = false
          }
          
          try await viewModel.createProject(projectName: self.projectNameText)
          
          await MainActor.run { self.checkEffectActive = true }
          
          try? await Task.sleep(for: .seconds(2)) // 애니메이션 2초 효과
          
          await MainActor.run { dismiss() }
        }
      }
      .disabled(isCreatingProject)
      
      // 로딩 오버레이
      if isCreatingProject {
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
  
  
  // MARK: - 프로젝트 생성 시, 완료 뷰
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
                isActive: !checkEffectActive  // 이 값이 false → true로 바뀔 때 한 번 그림
              )
          } else {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 24, weight: .medium))
              .foregroundStyle(Color.secondaryNormal)
          }
          
          Text("프로젝트를 생성했습니다.")
            .font(.headline2SemiBold)
            .foregroundStyle(Color.secondaryNormal)
            .opacity(checkEffectActive ? 1 : 0)
        }
      }
  }
}

#Preview {
  NavigationStack {
    CreateProjectView()
  }
}

