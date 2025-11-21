//
//  ProjectModals.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/21/25.
//

import SwiftUI

struct ProjectListModalsModifier: ViewModifier {

  @Bindable var homeViewModel: HomeViewModel
  @Bindable var projectListViewModel: ProjectListViewModel
  @Binding var tracksViewModel: TracksListViewModel?

  // 로컬 fail 상태는 ProjectListView가 소유하고 여기로 binding 전달
  @Binding var failDeleteTrack: Bool
  @Binding var failEditTrack: Bool
  @Binding var failDeleteProject: Bool
  @Binding var failEditProject: Bool

  // 권한 체크는 ProjectListView의 로직을 그대로 재사용하기 위해 클로저로 주입
  let canDeletePendingTrack: () -> Bool
  let canDeletePendingProject: () -> Bool

  func body(content: Content) -> some View {
    content
      // 프로젝트 삭제 Alert
      .alert(
        "\(projectListViewModel.presentationState.pendingDeleteProject?.projectName ?? "")를\n삭제하시겠어요?",
        isPresented: $projectListViewModel.presentationState.isPresentingDeleteAlert
      ) {
        Button("취소", role: .cancel) {}
        Button("삭제", role: .destructive) {
          guard canDeletePendingProject() else {
            failDeleteProject = true
            return
          }
          Task {
            await projectListViewModel.confirmDelete()
            projectListViewModel.presentationState.showCompletedToast = true
          }
        }
      } message: {
        Text("프로젝트 모든 내용이 삭제됩니다.")
      }

      // 프로젝트 이름 수정 불가능 Alert
      .alert(
        "프로젝트 이름 수정 권한이 없습니다.",
        isPresented: $failEditProject
      ) {
        Button("확인", role: .cancel) {}
      }

      // 프로젝트 삭제 불가 Alert
      .alert(
        "프로젝트 삭제 권한이 없습니다.",
        isPresented: $failDeleteProject
      ) {
        Button("확인", role: .cancel) {}
      }

      // 프로젝트 생성 sheet
      .sheet(isPresented: $projectListViewModel.presentationState.presentingCreateProjectSheet) {
        CreateProjectView {
          Task {
            await projectListViewModel.onAppear()
          }
        }
        .appSheetStyle()
      }

      // 프로젝트 관련 토스트
      .toast(
        isPresented: $projectListViewModel.presentationState.showCompletedToast,
        duration: 2,
        position: .bottom,
        bottomPadding: 16
      ) {
        ToastView(text: "프로젝트가 삭제되었습니다.", icon: .check)
      }
      .toast(
        isPresented: $projectListViewModel.presentationState.showNameUpdateCompletedToast,
        duration: 2,
        position: .bottom,
        bottomPadding: 16
      ) {
        ToastView(text: "프로젝트 이름을 수정했습니다.", icon: .check)
      }
      .toast(
        isPresented: $projectListViewModel.presentationState.showNameUpdateFailToast,
        duration: 2,
        position: .bottom,
        bottomPadding: 16
      ) {
        ToastView(text: "프로젝트 이름 수정을 실패했습니다.", icon: .warning)
      }
      .toast(
        isPresented: $projectListViewModel.presentationState.showNameLengthToast,
        duration: 2,
        position: .bottom,
        bottomPadding: 16
      ) {
        ToastView(text: "프로젝트 이름은 20자 이내로 입력해주세요.", icon: .warning)
      }

      // 트랙 이름 길이 토스트
      .toast(
        isPresented: $projectListViewModel.presentationState.showNameLengthTrackToast,
        duration: 2,
        position: .bottom,
        bottomPadding: 16
      ) {
        ToastView(text: "곡 이름은 20자 이내로 입력해주세요.", icon: .warning)
      }

      // 트랙 이름 수정 완료 토스트 (tracksViewModel 바인딩)
      .toast(
        isPresented: Binding(
          get: { tracksViewModel?.presentationState.showUpdateTrackToast ?? false },
          set: { tracksViewModel?.presentationState.showUpdateTrackToast = $0 }
        ),
        duration: 2,
        position: .bottom,
        bottomPadding: 16
      ) {
        ToastView(text: "곡 이름을 수정했습니다.", icon: .check)
      }


      // 트랙 이름 수정 불가능 Alert
      .alert(
        "곡 이름 수정 권한이 없습니다.",
        isPresented: $failEditTrack
      ) {
        Button("확인", role: .cancel) {}
      }

      // 트랙 생성 sheet (tracksViewModel 존재 시만)
      .sheet(
        isPresented: Binding(
          get: { tracksViewModel?.alertState.presentingCreateTrackSheet ?? false },
          set: { tracksViewModel?.alertState.presentingCreateTrackSheet = $0 }
        )
      ) {
        if let tracksVM = tracksViewModel, let project = tracksVM.project {
          CreateTracksView(
            tracksListViewModel: tracksVM,
            choiceSelectedProject: project,
            onCreated: {
              Task {
                await tracksVM.loadTracks(forceRefresh: true)
              }
            }
          )
          .appSheetStyle()
        }
      }

      // 트랙 삭제 성공 토스트
      .toast(
        isPresented: Binding(
          get: { tracksViewModel?.presentationState.showDeleteCompletedToast ?? false },
          set: { tracksViewModel?.presentationState.showDeleteCompletedToast = $0 }
        ),
        duration: 2,
        position: .bottom,
        bottomPadding: 16
      ) {
        ToastView(text: "곡이 삭제되었습니다.", icon: .check)
      }
  }
}

extension View {
  func projectListModals(
    homeViewModel: HomeViewModel,
    projectListViewModel: ProjectListViewModel,
    tracksViewModel: Binding<TracksListViewModel?>,
    failDeleteTrack: Binding<Bool>,
    failEditTrack: Binding<Bool>,
    failDeleteProject: Binding<Bool>,
    failEditProject: Binding<Bool>,
    canDeletePendingTrack: @escaping () -> Bool,
    canDeletePendingProject: @escaping () -> Bool
  ) -> some View {
    modifier(
      ProjectListModalsModifier(
        homeViewModel: homeViewModel,
        projectListViewModel: projectListViewModel,
        tracksViewModel: tracksViewModel,
        failDeleteTrack: failDeleteTrack,
        failEditTrack: failEditTrack,
        failDeleteProject: failDeleteProject,
        failEditProject: failEditProject,
        canDeletePendingTrack: canDeletePendingTrack,
        canDeletePendingProject: canDeletePendingProject
      )
    )
  }
}
