//
//  CreateTracksView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/22/25.
//

import SwiftUI

struct CreateTracksView: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @State private var viewModel: CreateTracksViewModel = .init()
  @Bindable var tracksListViewModel: TracksListViewModel
  
  @State private var trackNameText = ""
  
  @FocusState private var isFocusTextField: Bool
  
  @State private var closeAlert: Bool = false
  @State private var isCreatingTrack: Bool = false
  
  let choiceSelectedProject: Project?
  
  @State var overText: Bool = false
  
  @State private var checkEffectActive: Bool = false //애니메이션 트리거 + 표시 조건
  
  var onCreated: () -> Void = {}
  
  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()
      
      VStack {
        Spacer().frame(height: 29)
        topTitleView
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
        Spacer()
        inputTrackNameView
          .padding(.horizontal, 16)
        Spacer()
        bottomButtonView
          .padding(.horizontal, 16)
      }
      .dismissKeyboardOnTap()
    }
    
    /// 나가기 Alert
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
  
  // MARK: - 탑 타이틀, 닫기 버튼 뷰
  private var topTitleView: some View {
    ZStack { // TODO: 서치
      // 가운데 정렬 타이틀
      Text("곡 추가하기")
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
          .onTapGesture {  self.closeAlert = true }
        Spacer()
      }
    }
  }
  
  // MARK: - 곡 텍스트 필드 뷰 ("곡 이름" + 텍스트 필드)
  private var inputTrackNameView: some View {
    VStack {
      Text("추가할 곡의 이름을 입력하세요")
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
    TextField("(예시) SEVENTEEN - 만세", text: $trackNameText)
      .font(.headline2Medium)
      .foregroundStyle(Color.labelStrong)
      .tint(Color.labelStrong)
      .multilineTextAlignment(.center)
      .onChange(of: trackNameText) { oldValue, newValue in
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
        if trackNameText != result.text {
          trackNameText = result.text
        }
        
        // 4) 경고 플래그 반영
        overText = result.overText
      }
      .frame(maxWidth: .infinity)
      .frame(height: 51)
      .overlay(alignment: .trailing) {
        XmarkButton {
          self.trackNameText = ""
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
      Text("\(trackNameText.count)/20")
        .font(.headline2Medium)
        .foregroundStyle(Color.secondaryNormal)
    } else {
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(Color.accentRedNormal)
        .opacity(self.overText ? 1 : 0)
    }
  }
  
  // MARK: - 바텀 곡 만들기 뷰
  private var bottomButtonView: some View {
    ZStack {
      ActionButton(
        title: "곡 추가하기",
        color: trackNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
        height: 47,
        isEnabled: !trackNameText.isEmpty && !isCreatingTrack
      ) {
        Task {
          guard !trackNameText.isEmpty else { return }
          
          isCreatingTrack = true
          
          defer {
            isCreatingTrack = false
          }
          
          try await viewModel.createTracks(
            projectId: choiceSelectedProject?.projectId.uuidString ?? "",
            tracksName: trackNameText
          )
          
          await MainActor.run {
            onCreated()
            checkEffectActive = true
          }
          
          try? await Task.sleep(for: .seconds(2)) // 애니메이션 2초 효과
          
          await MainActor.run {
            dismiss()
          }
        }
      }
      .disabled(isCreatingTrack)
      
      // 로딩 오버레이
      if isCreatingTrack {
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
              .opacity(checkEffectActive ? 1 : 0)
          }
          
          Text("곡을 생성했습니다.")
            .font(.headline2SemiBold)
            .foregroundStyle(Color.secondaryNormal)
            .opacity(checkEffectActive ? 1 : 0)
        }
      }
  }
}

#Preview {
  NavigationStack {
    CreateTracksView(
      tracksListViewModel: TracksListViewModel(
        project: Project(
          projectId: UUID(),
          teamspaceId: "",
          creatorId: "",
          projectName: ""
        )
      ),
      choiceSelectedProject: nil
    )
  }
}

  
  
