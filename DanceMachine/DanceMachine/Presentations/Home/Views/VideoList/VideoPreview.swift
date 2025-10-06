//
//  VideoPreview.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/5/25.
//

import SwiftUI
import AVKit
import Photos

struct VideoPreview: View {
  @State private var player: AVPlayer?
  @State private var isLoading: Bool = false
  
  @Binding var selectedAsset: PHAsset?
  
//  let asset: PHAsset
  let onConfirm: (URL, UIImage, Double) -> Void
  
  var body: some View {
    
#if DEBUG
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      ZStack {
//        Color.black
//          .ignoresSafeArea(edges: .all)
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .frame(height: 240)
        Text("프리뷰 용")
          .multilineTextAlignment(.center)
          .font(.headline)
          .foregroundColor(.gray)
      }
    } else {
      realBody
    }
#else
    realBody
#endif
  
}
  
  private var realBody: some View {
    ZStack {
//      Color.black.opacity(0.5)
//        .ignoresSafeArea(edges: .all)
//      
      if isLoading {
        loadingView
      } else if let p = player {
        VideoPlayer(player: p)
          .aspectRatio(16/9, contentMode: .fit)
        //          .onAppear {
        //            p.play()
        //          }
      } else {
        Text("비디오를 선택해 주세요.")
          .foregroundStyle(.white)
      }
    }
    .onChange(of: selectedAsset, { oldValue, newValue in
      if newValue != nil {
        self.loadVideo()
      } else {
        self.player = nil
      }
    })
    .ignoresSafeArea()
  }
  
  private var loadingView: some View {
    VStack {
      ProgressView()
        .tint(.white)
        .scaleEffect(1.5)
      Text("로딩 중...")
        .foregroundStyle(.white)
        .padding(.top)
    }
  }
  
  private func loadVideo() {
    self.isLoading = true
//    defer { self.isLoading = false }
    
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    
    PHImageManager.default().requestPlayerItem(
      forVideo: selectedAsset ?? PHAsset(),
      options: options) { item, _ in
        DispatchQueue.main.async {
          if let pItem = item {
            self.player = AVPlayer(playerItem: pItem)
            self.isLoading = false
          }
        }
      }
  }
  
  private func exportVideo() {
    self.isLoading = true
    defer { self.isLoading = false }
    
    let o = PHVideoRequestOptions()
    o.isNetworkAccessAllowed = true
    o.deliveryMode = .highQualityFormat
    
    PHImageManager.default().requestAVAsset(
      forVideo: selectedAsset ?? PHAsset(),
      options: o) { avAsset, _, _ in
        guard let urlAsset = avAsset as? AVURLAsset else { return }
        
        Task {
          // 임시 폴더로 복사
          let fileName = "video_\(UUID().uuidString).mov"
          let tempURL = URL.temporaryDirectory.appending(component: fileName)
          
          do {
            // 파일 복사
            if FileManager.default.fileExists(atPath: tempURL.path()) {
              try FileManager.default.removeItem(at: tempURL)
              print("\(tempURL.path()) 임시 디렉토리 삭제")
            }
            try FileManager.default.copyItem(at: urlAsset.url, to: tempURL)
            print("\(tempURL.path()) 임시 디렉토리 추가")
            
            async let t = generateThumbnail(from: urlAsset)
            async let d = getDuration(from: urlAsset)
            
            let (thumbnail, duration) = try await (t, d)
            
            await MainActor.run {
              onConfirm(tempURL, thumbnail ?? UIImage(), duration)
              isLoading = false
              
            }
          } catch {
            print("비디오 복사 실패")
          }
        }
      }
  }
  
  private func generateThumbnail(
    from asset: AVURLAsset
  ) async throws-> UIImage? {
    
    let imageG = AVAssetImageGenerator(asset: asset)
    imageG.appliesPreferredTrackTransform = true
    
    let t = CMTime(seconds: 1, preferredTimescale: 60)
    
    let (cgImage, _) = try await imageG.image(at: t)
    return UIImage(cgImage: cgImage)
  }
  
  private func getDuration(
    from asset: AVURLAsset
  ) async throws -> Double {
    
    let d = try await asset.load(.duration)
    return CMTimeGetSeconds(d)
  }
}

#Preview {
  NavigationStack {
    VideoPreview(selectedAsset: .constant(PHAsset()), onConfirm: { _, _, _ in })
  }
}
