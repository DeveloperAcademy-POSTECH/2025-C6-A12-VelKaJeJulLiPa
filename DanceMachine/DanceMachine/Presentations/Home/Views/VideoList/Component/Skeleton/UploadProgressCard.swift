//
//  UploadProgressCard.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/3/25.
//

import SwiftUI

struct UploadProgressCard: View {
  let cardSize: CGFloat
  @Bindable var progressManager: VideoProgressManager
  let onRetry: () async -> Void
  let onCancel: () async -> Void

  var body: some View {
    card
  }
  
  private var card: some View {
    VStack(alignment: .leading) {
      thumbnail
        .overlay(alignment: .center) {
          switch progressManager.uploadState {
          case .uploading(let progress):
            uploadingView(progress: progress)
          case .failed(let message):
            failedView(message: message)
          case .idle:
            EmptyView()
          }
        }
      switch progressManager.uploadState {
      case .uploading( _):
        content
      case .failed(let message):
        failedMessage(message: message)
      case .idle:
        content
      }
//      content
//      if case .failed(let message) = progressManager.uploadState {
//        failedMessage(message: message)
//      }
      Spacer()
    }
    .frame(
      width: cardSize,
      height: cardSize * 1.22
    )
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.fillAssitive)
    )
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
  
  
  private var thumbnail: some View {
    VStack {
      topSkeletonView
        .frame(
          width: cardSize,
          height: cardSize / 1.5
        )
    }
  }
  
  private var content: some View {
    VStack(alignment: .leading) {
      
      bottomSkeletonView
        .frame(width: cardSize * 0.7, height: 20)
//      Spacer().frame(width: 8)
      bottomSkeletonView
        .frame(width: cardSize * 0.3, height: 16)
//      Spacer().frame(width: 4)
      bottomSkeletonView
        .frame(width: cardSize * 0.5, height: 15)
//      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 8)
    .padding(.horizontal, 8)
  }
  
  private var topSkeletonView: some View {
    SkeletonView(
      RoundedCorner(radius: 10, corners: [.topLeft, .topRight]),
      Color.fillNormal
    )
  }
  
  private var bottomSkeletonView: some View {
    SkeletonView(
      RoundedRectangle(cornerRadius: 5),
      Color.fillNormal
    )
  }

  // MARK: - Uploading
  private func uploadingView(progress: Double) -> some View {
    VStack {
      ZStack {
        Circle()
          .stroke(
            Color.fillAssitive,
            lineWidth: 4
          )
          .frame(
            width: cardSize / 2.5,
            height: cardSize / 2.5
          )
        Circle()
          .trim(from: 0, to: progress)
          .stroke(Color.secondaryNormal, lineWidth: 4)
          .frame(width: cardSize / 2.5, height: cardSize / 2.5)
          .rotationEffect(.degrees(90))

        VStack(spacing: 2) {
          Image(systemName: "arrow.up")
            .font(.system(size: 20, weight: .heavy))
            .foregroundStyle(Color.secondaryNormal)
          Text("\(Int(progress * 100))%")
            .font(.system(size: 14))
            .foregroundStyle(Color.secondaryNormal)
        }
      }
    }
  }

  // MARK: - Failed Reload Button
  private func failedView(message: String) -> some View {
    VStack(spacing: cardSize * 0.08) {
      // 재시도 버튼
      Button {
        Task { await onRetry() }
      } label: {
        ZStack {
          Circle()
            .stroke(Color.fillAssitive, lineWidth: 4)
            .frame(width: cardSize / 2.5, height: cardSize / 2.5)
          Image(systemName: "arrow.clockwise")
            .font(.system(size: cardSize * 0.2, weight: .bold))
            .foregroundStyle(Color.secondaryNormal)
        }
      }
    }
    .padding(.horizontal, cardSize * 0.1)
  }
  
  private func failedMessage(message: String) -> some View {
    // 에러 메시지
    VStack(alignment: .leading, spacing: 4) {
      Spacer().frame(height: 4)
      Text("업로드 실패")
//        .font(.system(size: cardSize * 0.08, weight: .semibold))
        .font(.headline2Medium)
        .foregroundStyle(Color.accentRedStrong)
      Spacer().frame(height: 4)
      Text(message)
//        .font(.system(size: cardSize * 0.06))
        .font(.caption1Medium)
        .foregroundStyle(Color.labelNormal)
        .multilineTextAlignment(.leading)
      // 취소 버튼
      Button {
        Task { await onCancel() }
      } label: {
        Text("취소")
//          .font(.system(size: cardSize * 0.07, weight: .medium))
          .font(.caption1Medium)
          .foregroundStyle(Color.accentRedStrong)
      }
    }
    .padding(.horizontal, 8)
  }
}

#Preview("Idle") {
  @Previewable @State var vm = VideoProgressManager.shared
  vm.uploadState = .idle
  return UploadProgressCard(
    cardSize: 172,
    progressManager: vm,
    onRetry: {},
    onCancel: {}
  )
}

#Preview("Uploading") {
  @Previewable @State var vm = VideoProgressManager.shared
  vm.uploadState = .uploading(progress: 0.65)
  return UploadProgressCard(
    cardSize: 172,
    progressManager: vm,
    onRetry: {},
    onCancel: {}
  )
}

#Preview("Failed") {
  @Previewable @State var vm = VideoProgressManager.shared
  vm.uploadState = .failed(message: "네트워크 연결을 확인하고\n다시 시도해주세요.")
  return UploadProgressCard(
    cardSize: 172,
    progressManager: vm,
    onRetry: {},
    onCancel: {}
  )
}
