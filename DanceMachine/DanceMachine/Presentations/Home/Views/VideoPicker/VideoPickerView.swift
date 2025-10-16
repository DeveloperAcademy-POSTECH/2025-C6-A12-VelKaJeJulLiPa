//
//  CustomPickerView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/5/25.
//

import SwiftUI
import Photos
import AVKit

struct VideoPickerView: View {
  @Environment(\.dismiss) private var dismiss
  
  @State private var vm: VideoPickerViewModel = .init()
  
  let tracksId: String
  let sectionId: String
  
  var body: some View {
    NavigationStack {
      GeometryReader { g in
        let spacing: CGFloat = 1
        let totalSpacing = spacing * 2
        let itemWidth = (g.size.width - totalSpacing) / 4
        ScrollView {
          
          VideoPreview(
            vm: vm,
            size: g.size.height * 0.5
          )
          .frame(height: g.size.height * 0.5)
          .padding(.top, (g.size.height * 0.5) / 3)
          
          CustomPicker(
            videos: $vm.videos,
            selectedAsset: $vm.selectedAsset,
            spacing: spacing,
            itemWidth: itemWidth
          )
        }
        .ignoresSafeArea(.all)
        .toolbar {
          ToolbarLeadingBackButton(icon: .chevron)
          ToolbarCenterTitle(text: "비디오 선택")
          ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
              vm.exportVideo(tracksId: tracksId, sectionId: sectionId)
            } label: {
              Text("저장")
            }
          }
        }
        .onAppear {
          vm.requestPermissionAndFetch()
        }
        .alert(
          "업로드 성공",
          isPresented: $vm.showSuccessAlert
        ) {
          Button("확인") {
            dismiss()
          }
        }
        .alert(
          "업로드 실패",
          isPresented: .constant(vm.errorMessage != nil)
        ) {
          Button("확인") {
            vm.errorMessage = nil
          }
        } message: {
          Text(vm.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
      }
    }
  }
}

#Preview {
  VideoPickerView(tracksId: "", sectionId: "")
}
