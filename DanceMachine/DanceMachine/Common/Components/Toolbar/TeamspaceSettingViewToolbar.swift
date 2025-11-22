//
//  TeamspaceSettingViewToolbar.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/18/25.
//

import SwiftUI

struct TeamspaceSettingViewToolbar: ToolbarContent {

  @Bindable var viewModel: TeamspaceSettingViewModel

  fileprivate enum Layout {
    enum Principal {
      static let navigationImageName: String = "chevron.down.circle.fill"
      static let navigationImageWidth: CGFloat = 22
      static let navigationImageHeight: CGFloat = 21
      static let navigationTextLinelimit: Int = 1
      static let checkImageName: String = "checkmark"
      static let createTeamspaceImageName: String = "plus.circle"
      static let createTeamspaceTitle: String = "새 팀 스페이스 만들기"
      static let hstackSpacing: CGFloat = 4
      static let sheetTitle: String = "팀 스페이스 선택"
    }

    enum TopBarTrailing {
      static let menuImageName: String = "ellipsis"
      static let menuImageNameWidth: CGFloat = 24
      static let menuImageNameHeight: CGFloat = 20
      static let menuImageFontSize: CGFloat = 17
      static let nameUpdateTitle: String = "팀 스페이스 이름 수정"
      static let nameUpdateImageName: String = "pencil"
      static let removeTeamMemberTitle: String = "팀원 내보내기"
      static let removeTeamMemberImage: String = "person.fill.badge.minus"
    }
  }

  var body: some ToolbarContent {

    if #available(iOS 26.0, *) {

      // iOS 26: 기존 Menu 유지
      ToolbarItem(placement: .principal) {
        Menu {
          if viewModel.teamspaceChoiceState.loading == true {
            Text("팀 스페이스 불러오는 중...")
              .font(.heading1SemiBold)
              .foregroundStyle(Color.labelStrong)
          } else {
            ForEach(viewModel.teamspaceChoiceState.teamspace, id: \.teamspaceId) { teamspace in
              Button {
                viewModel.selectTeamspace(teamspace)
                Task { await viewModel.onAppear() }
              } label: {
                HStack {
                  Text(teamspace.teamspaceName)

                  Spacer()

                  if viewModel.currentTeamspace?.teamspaceId == teamspace.teamspaceId {
                    Image(systemName: Layout.Principal.checkImageName)
                  }
                }
              }
            }
          }

          Divider()

          Button {
            viewModel.teamspaceSettingPresentationState.isPresentingCreateTeamspaceSheet = true
          } label: {
            Label(
              Layout.Principal.createTeamspaceTitle,
              systemImage: Layout.Principal.createTeamspaceImageName
            )
          }

        } label: {
          Button {
            Task { await viewModel.loadUserTeamspace() }
          } label: {
            HStack(spacing: Layout.Principal.hstackSpacing) {
              Text(viewModel.dataState.selectedTeamspaceName)
                .font(.heading1Medium)
                .foregroundStyle(Color.labelStrong)
                .lineLimit(Layout.Principal.navigationTextLinelimit)

              Image(systemName: Layout.Principal.navigationImageName)
                .resizable()
                .scaledToFit()
                .frame(
                  width: Layout.Principal.navigationImageWidth,
                  height: Layout.Principal.navigationImageHeight
                )
                .foregroundStyle(Color.labelAssitive)
            }
          }
        }
      }

    } else {

      // iOS 18: sheet 기반 선택 UI
      ToolbarItem(placement: .principal) {
        TeamspacePickerPrincipalButton(viewModel: viewModel)
      }
    }

    if viewModel.dataState.teamspaceRole == .owner {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button {
            viewModel.teamspaceSettingPresentationState.isPresentingUpdateTeamspaceNameSheet = true
          } label: {
            Label(
              Layout.TopBarTrailing.nameUpdateTitle,
              systemImage: Layout.TopBarTrailing.nameUpdateImageName
            )
          }

          Divider()

          Button(role: .destructive) {
            viewModel.dataState.memberListMode = .removing
          } label: {
            Label(
              Layout.TopBarTrailing.removeTeamMemberTitle,
              systemImage: Layout.TopBarTrailing.removeTeamMemberImage
            )
          }

        } label: {
          Image(systemName: Layout.TopBarTrailing.menuImageName)
            .resizable()
            .scaledToFit()
            .frame(
              width: Layout.TopBarTrailing.menuImageNameWidth,
              height: Layout.TopBarTrailing.menuImageNameHeight
            )
            .font(.system(size: Layout.TopBarTrailing.menuImageFontSize, weight: .medium))
            .foregroundStyle(Color.labelStrong)
        }
      }
    }
  }
}

private struct TeamspacePickerPrincipalButton: View {

  @Bindable var viewModel: TeamspaceSettingViewModel

  @State private var isPresentingPicker: Bool = false

  fileprivate enum Layout {
    enum Principal {
      static let navigationImageName: String = "chevron.down.circle.fill"
      static let navigationImageWidth: CGFloat = 22
      static let navigationImageHeight: CGFloat = 21
      static let navigationTextLinelimit: Int = 1
      static let checkImageName: String = "checkmark"
      static let createTeamspaceImageName: String = "plus.circle"
      static let createTeamspaceTitle: String = "새 팀 스페이스 만들기"
      static let hstackSpacing: CGFloat = 4
      static let sheetTitle: String = "팀 스페이스 선택"
    }
  }

  var body: some View {
    Button {
      Task {
        await viewModel.loadUserTeamspace()
        await MainActor.run { isPresentingPicker = true }
      }
    } label: {
      HStack(spacing: Layout.Principal.hstackSpacing) {
        Text(viewModel.dataState.selectedTeamspaceName)
          .font(.heading1Medium)
          .foregroundStyle(Color.labelStrong)
          .lineLimit(Layout.Principal.navigationTextLinelimit)

        Image(systemName: Layout.Principal.navigationImageName)
          .resizable()
          .scaledToFit()
          .frame(
            width: Layout.Principal.navigationImageWidth,
            height: Layout.Principal.navigationImageHeight
          )
          .foregroundStyle(Color.labelAssitive)
      }
      .contentShape(Rectangle())
    }
    .sheet(isPresented: $isPresentingPicker) {
      TeamspacePickerSheet(
        viewModel: viewModel,
        isPresented: $isPresentingPicker
      )
    }
  }
}

private struct TeamspacePickerSheet: View {

  @Bindable var viewModel: TeamspaceSettingViewModel
  @Binding var isPresented: Bool

  fileprivate enum Layout {
    enum Principal {
      static let sheetTitle: String = "팀 스페이스 선택"
      static let checkImageName: String = "checkmark"
      static let createTeamspaceImageName: String = "plus.circle"
      static let createTeamspaceTitle: String = "새 팀 스페이스 만들기"
    }
  }

  var body: some View {
    VStack(spacing: 0) {

      HStack {
        Text(Layout.Principal.sheetTitle)
          .font(.headline2SemiBold)
          .foregroundStyle(Color.labelStrong)
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 8)

      if viewModel.teamspaceChoiceState.loading == true {
        VStack {
          Spacer()
          ProgressView()
          Spacer()
        }
      } else {
        List {
          ForEach(viewModel.teamspaceChoiceState.teamspace, id: \.teamspaceId) { teamspace in
            Button {
              viewModel.selectTeamspace(teamspace)
              Task { await viewModel.onAppear() }
              isPresented = false
            } label: {
              HStack {
                Text(teamspace.teamspaceName)
                  .foregroundStyle(Color.labelStrong)

                Spacer()

                if viewModel.currentTeamspace?.teamspaceId == teamspace.teamspaceId {
                  Image(systemName: Layout.Principal.checkImageName)
                    .foregroundStyle(Color.labelAssitive)
                }
              }
            }
          }
        }
        .listStyle(.plain)
      }

      Divider()

      Button {
        isPresented = false
        viewModel.teamspaceSettingPresentationState.isPresentingCreateTeamspaceSheet = true
      } label: {
        HStack(spacing: 8) {
          Image(systemName: Layout.Principal.createTeamspaceImageName)
          Text(Layout.Principal.createTeamspaceTitle)
        }
        .font(.headline2Medium)
        .foregroundStyle(Color.secondaryStrong)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
    }
    .presentationDetents([.medium])
    .presentationCornerRadius(16)
  }
}
