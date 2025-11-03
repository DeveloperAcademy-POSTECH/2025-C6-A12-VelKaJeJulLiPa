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
  
  @State private var showEmptyTitleAlert: Bool = false
  @State private var showEmptyVideoAlert: Bool = false
  
  @FocusState private var isFocused: Bool
  
  let tracksId: String
  let sectionId: String
  
  var body: some View {
    NavigationStack {
      ZStack {
        // 권한이 없을 때 권한 요청 화면 표시
        if vm.photoLibraryStatus == .denied || vm.photoLibraryStatus == .restricted {
          PhotoLibraryPermissionView {
            vm.openSettings()
          }
        } else {
          // 권한이 있을 때 기존 UI 표시
          mainContent
        }
      }
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarLeadingBackButton(icon: .xmark)
        ToolbarCenterTitle(text: "비디오 선택")
        
        if vm.photoLibraryStatus == .authorized || vm.photoLibraryStatus == .limited {
          ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
              if vm.selectedAsset == nil {
                self.showEmptyVideoAlert = true
                return
              } else if vm.videoTitle == "" {
                self.showEmptyTitleAlert = true
                return
              }
              vm.exportVideo(tracksId: tracksId, sectionId: sectionId)
              dismiss()
            } label: {
              Image(systemName: "arrow.up")
                .foregroundStyle(
                  vm.selectedAsset == nil ? .black.opacity(0.7) : .white
                )
            }
            .disabled(vm.isLoading)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
          }
        }
      }
      .task {
        await vm.requestPermissionAndFetch()
      }
      .alert("비디오를 선택해주세요!", isPresented: $showEmptyVideoAlert) {
        Button("확인") {
          self.showEmptyVideoAlert = false
        }
      }
      .alert("파일명을 입력하세요!", isPresented: $showEmptyTitleAlert) {
        Button("확인") {
          self.showEmptyTitleAlert = false
        }
      }
      .alert("업로드 실패", isPresented: .constant(vm.errorMessage != nil)) {
        Button("확인") {
          vm.errorMessage = nil
        }
      } message: {
        Text(vm.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
      }
    }
    .background(Color.white)
    .disabled(vm.isLoading)
  }
  // MARK: 권한 허용 뷰
  private var mainContent: some View {
    GeometryReader { g in
      let spacing: CGFloat = 1
      let totalSpacing = spacing * 2
      let itemWidth = (g.size.width - totalSpacing) / 4
      
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 16) {
            Color.clear
              .frame(height: 0)
              .id("TOP")
            
            VideoPreview(
              vm: vm,
              size: 224
            )
            
            textField
            
            CustomPicker(
              videos: $vm.videos,
              selectedAsset: $vm.selectedAsset,
              spacing: spacing,
              itemWidth: itemWidth
            )
          }
        }
        .onChange(of: vm.selectedAsset) { oldValue, newValue in
          withAnimation(.easeInOut) {
            proxy.scrollTo("TOP", anchor: .top)
          }
        }
      }
      .overlay {
        if vm.isLoading {
          ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 16) {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .tint(.black)
                .scaleEffect(1)
              
              if vm.uploadProgress > 0 {
                Text("업로드 중... \(Int(vm.uploadProgress * 100))%")
                  .foregroundStyle(.purple)
                  .font(.system(size: 14))
              } else {
                Text("준비 중...")
                  .foregroundStyle(.purple)
                  .font(.system(size: 14))
              }
            }
          }
          .ignoresSafeArea()
        }
      }
    }
  }
  
  private var textField: some View {
    RoundedRectangle(cornerRadius: 10)
      .fill(Color.gray.opacity(0.6)) // FIXME: 컬러 수정
      .frame(maxWidth: .infinity)
      .frame(height: 51)
      .overlay {
        TextField("파일명을 입력하세요.", text: $vm.videoTitle)
          .padding()
          .textFieldStyle(.plain)
          .font(.system(size: 16)) // FIXME: 폰트 수정
          .foregroundStyle(Color.gray)
          .focused($isFocused)
      }
      .padding(.horizontal, 16)
  }
}

#Preview {
  VideoPickerView(tracksId: "", sectionId: "")
}
