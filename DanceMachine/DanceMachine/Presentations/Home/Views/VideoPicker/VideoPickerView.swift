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
  
  @Bindable var pickerViewModel: VideoPickerViewModel
  
  @State private var showEmptyTitleAlert: Bool = false
  @State private var showEmptyVideoAlert: Bool = false
  @State private var showToast: Bool = false
  
  @FocusState private var isFocused: Bool
  
  let tracksId: String
  let sectionId: String
  let trackName: String
  
  private var vm: VideoPickerViewModel { pickerViewModel }
  
  var body: some View {
    NavigationStack {
      ZStack {
        mainContent
        
        // iCloud 다운로드 오버레이
        if vm.isDownloadingFromCloud {
          iCloudOverlay
        }
      }
      .toast(
        isPresented: $showToast,
        duration: 2,
        position: .bottom,
        bottomPadding: 16,
        content: {
          ToastView(text: "20자 미만으로 입력해주세요.", icon: .warning)
        }
      )
      .dismissKeyboardOnTap()
      .background(Color.fillNormal)
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarLeadingBackButton(icon: .xmark)
        ToolbarItem(placement: .title) {
          centerToolbar
        }
        if vm.photoLibraryStatus == .authorized || vm.photoLibraryStatus == .limited {
          ToolbarItemGroup(placement: .topBarTrailing) {
            trailingToolbar
          }
        }
      }
      .task {
        await vm.requestPermissionAndFetch()
      }
      .alert("업로드 실패", isPresented: .constant(vm.errorMessage != nil)) {
        Button("확인") {
          vm.errorMessage = nil
        }
      } message: {
        Text(vm.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
      }
    }
    .background(Color.fillNormal)
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
              videos: $pickerViewModel.videos,
              selectedAsset: $pickerViewModel.selectedAsset,
              spacing: spacing,
              itemWidth: itemWidth
            )
          }
        }
        .onChange(of: vm.selectedAsset) { oldValue, newValue in
          withAnimation(.easeInOut) {
            proxy.scrollTo("TOP", anchor: .top)
            self.isFocused = false
          }
        }
      }
    }
  }
  
  private var iCloudOverlay: some View {
    ZStack {
      Color.black.opacity(0.7)
        .ignoresSafeArea()
      
      VStack(spacing: .zero) {
        ProgressView(value: vm.downloadProgress)
          .progressViewStyle(.linear)
          .tint(.secondaryNormal)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 16)
        Spacer().frame(height: 18)
        Text("iCloud로부터 미디어 다운받는 중")
          .font(.headline2Medium)
          .foregroundColor(.labelStrong)
        Spacer().frame(height: 6)
        Text("\(Int(vm.downloadProgress * 100))%")
          .font(.headline2Medium)
          .foregroundColor(.labelStrong)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 20)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.fillStrong)
      )
      .padding(.horizontal, 64)
    }
  }
  
  private var textField: some View {
    RoundedRectangle(cornerRadius: 15)
      .fill(Color.fillStrong)
      .frame(maxWidth: .infinity)
      .frame(height: 51)
      .overlay {
        TextField(
          vm.selectedAsset == nil ? "업로드할 동영상을 선택하세요." : "동영상 제목을 입력해주세요.",
          text: $pickerViewModel.videoTitle
        )
        .padding()
        .textFieldStyle(.plain)
        .font(.headline2Medium)
        .foregroundStyle(Color.labelStrong)
        .focused($isFocused)
        .onChange(of: vm.videoTitle) { oldValue, newValue in
          let updated = newValue.sanitized(limit: 20)
          if vm.videoTitle.count > 19 {
            self.showToast = true
          }
          if updated != vm.videoTitle {
            vm.videoTitle = updated
          }
        }
      }
      .overlay {
        if isFocused == true {
          textOverlay
        }
      }
      .padding(.horizontal, 16)
  }
  // MARK: 텍스트필드에 오버레이 되는 글자수와 xmark 스트로크
  private var textOverlay: some View {
    RoundedRectangle(cornerRadius: 15)
      .stroke(vm.videoTitle.count > 19 ? .accentRedNormal : .secondaryStrong, lineWidth: 1)
      .overlay(alignment: .trailing) {
        HStack(spacing: 0) {
          Text("\(vm.videoTitle.count)/20")
            .font(.headline2Medium)
            .foregroundStyle(vm.videoTitle.count > 19 ? .accentRedNormal : .secondaryNormal)
          Button {
            vm.videoTitle = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .frame(width: 44, height: 44)
              .foregroundStyle(.labelNormal)
          }
        }
      }
  }
  // MARK: 커스텀 툴바 센터 타이틀
  private var centerToolbar: some View {
    VStack(alignment: .center) {
      Text("동영상 업로드")
        .font(.headline2SemiBold)
        .foregroundStyle(.labelStrong)
      Text("\(trackName)")
        .font(.caption1Medium)
        .foregroundStyle(.labelNormal)
    }
  }
  // 커스텀 툴바 트레일링 버튼
  // 영상 선택, 영상 제목 비어있을 때, 글자 수 케이스
  private var trailingToolbar: some View {
    Button {
      if vm.selectedAsset == nil {
        self.showEmptyVideoAlert = true
        return
      } else if vm.videoTitle == "" {
        self.isFocused = true
        return
      } else if vm.videoTitle.count > 19 {
        self.showToast = true
        return
      }
      self.isFocused = false
      // iCloud 다운로드 완료 후 피커 닫기
      vm.exportVideo(tracksId: tracksId, sectionId: sectionId) {
        dismiss()
      }
    } label: {
      Image(systemName: "arrow.up")
        .foregroundStyle(
          vm.selectedAsset == nil ? Color.labelAssitive : Color.labelStrong
        )
    }
    .disabled(vm.selectedAsset == nil)
    .buttonStyle(.borderedProminent)
    .tint(Color.secondaryStrong)
  }
}

#Preview {
  VideoPickerView(
    pickerViewModel: VideoPickerViewModel(),
    tracksId: "",
    sectionId: "",
    trackName: "벨코의 리치맨"
  )
}
