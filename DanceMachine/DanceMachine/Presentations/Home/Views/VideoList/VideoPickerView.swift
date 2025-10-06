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
  
  @State private var videos: [PHAsset] = [] // 이미지 및 비디오, 라이브포토를 나타내는 모델
  @State var selectedAsset: PHAsset? = nil
  @State private var showPreview: Bool = false
  
  @State private var isLoading: Bool = false
  @State private var player: AVPlayer?
  
  let onSelect: (URL, UIImage, Double) -> Void
  
  // MARK: 뷰 나누자
  var body: some View {
    NavigationStack {
      GeometryReader { g in
        let spacing: CGFloat = 1
        let totalSpacing = spacing * 2
        let itemWidth = (g.size.width - totalSpacing) / 4
        ScrollView {
          GeometryReader { scroll in
            let minY = scroll.frame(in: .global).minY
            let header = g.size.height * 0.7
            ZStack {
              Color.black.opacity(0.2)
                .ignoresSafeArea(.all)
//                .frame(height: header + (minY > 0 ? minY : 0))
//                .offset(y: minY > 0 ? -minY : 0)
              
              VideoPreview(
                selectedAsset: $selectedAsset) { url, thumbnail, duration in
                  onSelect(url, thumbnail, duration)
                }
                .padding(.top, 55)
//                .frame(height: header + (minY > 0 ? minY : 0))
//                .offset(y: minY > 0 ? -minY : 0)
            }
          }
          .frame(height: g.size.height * 0.7)
          
          CustomPicker(
            videos: $videos,
            selectedAsset: $selectedAsset,
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
              //
            } label: {
              Text("저장")
            }
          }
        }
        .onAppear {
          requestPermissionAndFetch()
        }
      }
    }
  }
  
  private func requestPermissionAndFetch() {
#if DEBUG
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      DispatchQueue.main.async {
        self.videos = []
      }
      return
    }
#endif
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      switch status {
      case .authorized:
        fetchVideos()
      case .denied, .restricted:
        print("사진 라이브러리 접근 거부 또는 제한") // TODO: 처리 필요
      case .notDetermined:
        print("사용자가 아직 선택하지 않음") // TODO: 처리 필요
      case .limited:
        print("권한 제한") // TODO: 처리 필요
      @unknown default:
        fatalError("알 수 없는 권한 상태") // TODO: 처리 필요
      }
      //      if status == .authorized {
      //        fetchVideos()
      //      }
    }
  }
  
  private func fetchVideos() {
    // Asset 혹은 Collection 객체를 가져올 때 이들에 대한 필터링 및 정렬을 정의할 수 있는 객체
    let fetchOptions = PHFetchOptions()
    
    //  NSPredicate 타입인 predicate를 사용하여 필터링을 정의하고, NSSortDescriptor 타입인 sortDescriptors를 사용하여 정렬을 정의
    fetchOptions.sortDescriptors =
    [NSSortDescriptor(key: "creationDate", ascending: false)]
    
    let results = PHAsset.fetchAssets(with: .video, options: fetchOptions)
    
    var fetchedVideos: [PHAsset] = []
    results.enumerateObjects { asset, _, _ in
      fetchedVideos.append(asset)
    }
    
    DispatchQueue.main.async {
      self.videos = fetchedVideos
    }
  }
}

#Preview {
  VideoPickerView(onSelect: {_, _, _ in })
}

// MARK: FullScreenCover(isPresented)로 했을 때 오류 해결을 위함
extension PHAsset: Identifiable {
  public var id: String {
    return self.localIdentifier
  }
}
