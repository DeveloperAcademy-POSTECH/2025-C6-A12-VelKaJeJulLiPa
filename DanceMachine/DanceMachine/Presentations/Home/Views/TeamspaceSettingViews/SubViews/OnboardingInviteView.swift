//
//  OnboardingInviteView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/20/25.
//

import SwiftUI

struct OnboardingInviteView: View {
  
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel: OnboardingInviteViewModel = .init()
  
  fileprivate struct Layout {
    enum MiddleContentView {
      static let imageName: String = "person.2.fill"
      static let imageSize: CGFloat = 110
      static let vstackSpacing: CGFloat = 27
      static let titleText: String = "팀 스페이스에 팀원을 초대해 보세요."
      static let subTitleText: String = "팀원 태그를 통해 피드백을 주고받을 수 있습니다."
    }
    enum BottomActionButtonView {
      static let bottomActionButtonViewVstackSpacing: CGFloat = 24
      static let nextButtonText: String = "다음에 하기"
      static let inviteButtonText: String = "팀에 멤버 초대하기"
      static let inviteButtonHeight: CGFloat = 47
    }
  }
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      VStack {
        middleContentView
        Spacer()
        bottomActionButtonView
      }
      .padding(.horizontal, 16)
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .xmark) {
        router.popToRootView()
      }
      ToolbarCenterTitle(text: "팀 스페이스 만들기")
    }
  }
  
  // MARK: - 미들 설명 뷰
  private var middleContentView: some View {
    VStack(spacing: Layout.MiddleContentView.vstackSpacing) {
      Spacer()
      Image(systemName: Layout.MiddleContentView.imageName)
        .font(.system(size: Layout.MiddleContentView.imageSize))
        .foregroundStyle(Color.fillAlternative)
        .frame(maxWidth: .infinity)
      Text(Layout.MiddleContentView.titleText)
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      Text(Layout.MiddleContentView.subTitleText)
        .font(.body1Medium)
        .foregroundStyle(Color.labelNormal)
      Spacer()
    }
  }
  
  // MARK: - 바텀 액션 버튼 뷰
  private var bottomActionButtonView: some View {
    VStack(spacing: Layout.BottomActionButtonView.bottomActionButtonViewVstackSpacing) {
      
      Button {
        router.popToRootView()
      } label: {
        Text(Layout.BottomActionButtonView.nextButtonText)
          .font(.headline2Medium)
          .foregroundStyle(Color.secondaryNormal)
      }
      
      ActionButton(
        title: Layout.BottomActionButtonView.inviteButtonText,
        color: Color.secondaryStrong,
        height: Layout.BottomActionButtonView.inviteButtonHeight) {
          Task {
            guard let item = await viewModel.makeInviteShareItem() else { return }
            await MainActor.run {
              let viewController = UIActivityViewController(
                activityItems: [item],
                applicationActivities: nil
              )
              UIApplication.shared.topMostViewController()?.present(viewController, animated: true)
            }
          }
        }
    }
  }
}

#Preview {
  NavigationStack {
    OnboardingInviteView()
  }
}
