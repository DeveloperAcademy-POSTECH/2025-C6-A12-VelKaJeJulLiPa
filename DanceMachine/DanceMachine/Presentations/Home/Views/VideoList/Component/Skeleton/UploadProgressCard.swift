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
          case .compressing(let progress):
            compressingView(progress: progress)
          case .fileToLarge( _):
            fileTooLargeView
          case .uploading(let progress):
            uploadingView(progress: progress)
          case .failed(let message):
            failedView(message: message)
          case .idle:
            EmptyView()
          }
        }
      switch progressManager.uploadState {
      case .compressing( _):
        content
      case .fileToLarge(let message):
        fileTooLargeMessage(message: message)
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
      height: cardSize * 1.037
    )
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.fillAssitive)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
  
  
  private var thumbnail: some View {
    VStack {
      topSkeletonView
        .frame(
          width: cardSize,
          height: cardSize / 1.79
        )
    }
  }
  
  private var content: some View {
    VStack(alignment: .leading) {
      Spacer().frame(height: 8)
      bottomSkeletonView
        .frame(width: cardSize * 0.7, height: 18)
      Spacer().frame(width: 8)
      bottomSkeletonView
        .frame(width: cardSize * 0.2, height: 12)
      Spacer().frame(width: 4)
      bottomSkeletonView
        .frame(width: cardSize * 0.4, height: 12)
//      Spacer().frame(height: 16)
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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
  
  // MARK: fileToLarge
  private var fileTooLargeView: some View {
    VStack {
      ZStack {
        Circle()
          .stroke(Color.fillAssitive, lineWidth: 5)
          .frame(width: cardSize / 3, height: cardSize / 3)
        Button {
          Task { await onCancel() }
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(Color.secondaryNormal)
        }
      }
    }
  }
  
  private func fileTooLargeMessage(message: String) -> some View {
    VStack(alignment: .leading) {
      Spacer().frame(height: 8)
      HStack {
        Image(systemName: "exclamationmark.circle")
          .foregroundStyle(.accentRedNormal)
        Text("용량 초과")
          .font(.headline2Medium)
          .foregroundStyle(.accentRedNormal)
      }
      Spacer().frame(height: 8)
      Text(message)
        .font(.caption1Medium)
        .foregroundStyle(Color.labelNormal)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 8)
  }
  
  // MARK: - Compressing
  private func compressingView(progress: Double) -> some View {
    VStack {
      ZStack {
        Circle()
          .stroke(
            Color.fillAssitive,
            lineWidth: 5
          )
          .frame(
            width: cardSize / 3,
            height: cardSize / 3
          )
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            Color.secondaryNormal,
            style: StrokeStyle(
              lineWidth: 5,
              lineCap: .round
            )
          )
          .frame(width: cardSize / 3, height: cardSize / 3)
          .rotationEffect(.degrees(90))

        VStack(spacing: 2) {
          Text("압축중")
            .font(.caption1Medium)
            .foregroundStyle(Color.secondaryNormal)
//          Text("\(Int(progress * 100))%")
//            .font(.caption1Medium)
//            .foregroundStyle(Color.secondaryNormal)
        }
      }
    }
  }

  // MARK: - Uploading
  private func uploadingView(progress: Double) -> some View {
    VStack {
      ZStack {
        Circle()
          .stroke(
            Color.fillAssitive,
            lineWidth: 5
          )
          .frame(
            width: cardSize / 3,
            height: cardSize / 3
          )
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            Color.secondaryNormal,
            style: StrokeStyle(
              lineWidth: 5,
              lineCap: .round
            )
          )
          .frame(width: cardSize / 3, height: cardSize / 3)
          .rotationEffect(.degrees(90))

        VStack(spacing: 2) {
          Image(systemName: "arrowshape.up.fill")
            .font(.system(size: 20))
            .foregroundStyle(Color.secondaryNormal)
          Text("\(Int(progress * 100))%")
            .font(.caption1Medium)
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
    VStack(alignment: .leading) {
      Spacer()
      HStack {
        Image(systemName: "exclamationmark.circle")
          .foregroundStyle(.accentRedNormal)
        Text("업로드 실패")
          .font(.headline2Medium)
          .foregroundStyle(.accentRedNormal)
      }
      Spacer().frame(height: 8)
      Text(message)
        .font(.caption1Medium)
        .foregroundStyle(Color.labelNormal)
        .multilineTextAlignment(.leading)
      Spacer().frame(height: 8)
      // 취소 버튼
      Button {
        Task { await onCancel() }
      } label: {
        Text("취소")
          .font(.caption1Medium)
          .foregroundStyle(.accentRedNormal)
      }
      Spacer()
    }
    .padding(.horizontal, 8)
  }
}

#Preview("fileToLarge") {
  @Previewable @State var vm = VideoProgressManager.shared
  vm.uploadState = .fileToLarge(message: "100MB까지 업로드 가능합니다.")
  return UploadProgressCard(
    cardSize: 172,
    progressManager: vm,
    onRetry: {},
    onCancel: {}
  )
}

#Preview("Compressing") {
  @Previewable @State var vm = VideoProgressManager.shared
  vm.uploadState = .compressing(progress: 0.65)
  return UploadProgressCard(
    cardSize: 172,
    progressManager: vm,
    onRetry: {},
    onCancel: {}
  )
}

//#Preview("Idle") {
//  @Previewable @State var vm = VideoProgressManager.shared
//  vm.uploadState = .idle
//  return UploadProgressCard(
//    cardSize: 172,
//    progressManager: vm,
//    onRetry: {},
//    onCancel: {}
//  )
//}

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
  vm.uploadState = .failed(message: "네트워크 상태를 확인해주세요.")
  return UploadProgressCard(
    cardSize: 172,
    progressManager: vm,
    onRetry: {},
    onCancel: {}
  )
}
