//
//  AISheetView.swift
//  DanceMachine
//
//  Created by 조재훈 on 1/22/26.
//

import SwiftUI
import DancePoseAnalysis

struct AISheetView: View {
  
  @Bindable var vm: VideoDetailViewModel
//  @State var vm: AIViewModel = .init()
  
  let videoId: String
  
  var body: some View {
    VStack {
      switch vm.aiVM.state {
      case .idle: idleView
      case .extracting: extractingView
      case .analyzing: analyzingView
      case .completed: completedView
      case .failed: failedView
      }
    }
  }

  private var idleView: some View {
    VStack(spacing: 24) {
      Image(systemName: "sparkles")
        .font(.system(size: 48))
        .foregroundStyle(.accentRedStrong)

      Text("AI 분석을 시작해 보세요!")
        .font(.title2)

      Text("Gemini 3 Vision이 영상을 직접 보고\n단체 안무의 완성도를 분석합니다")
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "eye.fill")
            .foregroundStyle(.blue)
          Text("영상 속 모든 댄서를 자동 감지")
        }

        HStack(spacing: 8) {
          Image(systemName: "sparkles")
            .foregroundStyle(.purple)
          Text("옷 색깔과 위치로 정확히 특정")
        }

        HStack(spacing: 8) {
          Image(systemName: "clock.fill")
            .foregroundStyle(.orange)
          Text("예상 소요 시간: 약 2-3분")
        }
      }
      .font(.callout)
      .padding()
      .background(Color.gray.opacity(0.05))
      .cornerRadius(12)

      Button {
        Task {
          await vm.aiVM.startAnalysis(videoId: videoId) { feedback in
            await vm.saveAIAnalysis(
              feedback,
              videoId: videoId
            )
          }
        }
      } label: {
        Text("분석 시작")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding()
          .background(.accentRedStrong)
          .foregroundStyle(.white)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      .padding(.horizontal)
    }
  }

  private var extractingView: some View {
    VStack(spacing: 24) {
      ProgressView()
        .scaleEffect(1.5)
        .tint(.accentRedStrong)

      VStack(spacing: 8) {
        Text("영상 업로드 중...")
          .font(.title3)
          .fontWeight(.semibold)
        Text("Gemini File API에 영상을 업로드하고 있습니다.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var analyzingView: some View {
    VStack(spacing: 24) {
      ProgressView()
        .scaleEffect(1.5)
        .tint(.accentRedStrong)
      
      VStack(spacing: 8) {
        Text("AI 분석 중...")
          .font(.title3)
          .fontWeight(.semibold)
        Text("동작 차이를 비교하고 피드백을 생성하고 있습니다.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var completedView: some View {
    ScrollView {
      if let feedback = vm.aiVM.visionFeedback {
        VStack(spacing: 20) {
          scoreSection(feedback: feedback)

          if !feedback.criticalErrors.isEmpty {
            criticalErrorsSection(feedback: feedback)
          }

          if let highlight = feedback.highlightMoment {
            highlightSection(highlight: highlight)
          }

          // 재분석 버튼
          Button {
            vm.aiVM.reset()
          } label: {
            HStack {
              Image(systemName: "arrow.clockwise")
              Text("다시 분석하기")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .padding(.top, 8)
        }
        .padding()
      }
    }
  }

  private var failedView: some View {
    VStack(spacing: 24) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 48))
        .foregroundStyle(.red)
      
      VStack(spacing: 8) {
        Text("분석 실패")
          .font(.title3)
          .fontWeight(.semibold)
        
        Text(vm.aiVM.errorMsg ?? "알 수 없는 오류가 발생했습니다.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      
      Button {
        vm.aiVM.reset()
      } label: {
        Text("다시 시도")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding()
          .background(.accentRedStrong)
          .foregroundStyle(.white)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
    .padding()
  }
}

#Preview("idle") {
  AISheetView(vm: VideoDetailViewModel(), videoId: "")
}

#Preview("extracting") {
  let vm = AIViewModel.preview(.extracting)
  return AISheetView(vm: VideoDetailViewModel(), videoId: "")
}

#Preview("analyzing") {
  let vm = AIViewModel.preview(.analyzing)
  return AISheetView(vm: VideoDetailViewModel(), videoId: "")
}

#Preview("completed") {
  let vm = AIViewModel.preview(.completed)
  return AISheetView(vm: VideoDetailViewModel(), videoId: "")
}

#Preview("failed") {
  let vm = AIViewModel.preview(.failed)
  return AISheetView(vm: VideoDetailViewModel(), videoId: "")
}

extension AISheetView {
  private func scoreSection(feedback: VisionFeedback) -> some View {
    VStack(spacing: 8) {
      Text("전체 동작 점수")
        .font(.headline)

      ZStack {
        Circle()
          .stroke(Color.gray.opacity(0.2), lineWidth: 10)
          .frame(width: 120, height: 120)

        Circle()
          .trim(from: 0, to: Double(feedback.overallScore) / 100)
          .stroke(scoreColor(Double(feedback.overallScore)), lineWidth: 10)
          .frame(width: 120, height: 120)
          .rotationEffect(.degrees(-90))

        VStack(spacing: 4) {
          Text("\(feedback.overallScore)")
            .font(.system(size: 36, weight: .bold))
          Text("점")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Text(scoreComment(feedback.overallScore))
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
  }

  private func criticalErrorsSection(feedback: VisionFeedback) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
        Text("교정 필요 (\(feedback.criticalErrors.count))")
          .font(.headline)
      }

      ForEach(feedback.criticalErrors) { error in
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            // 시간 표시
            HStack(spacing: 4) {
              Image(systemName: "clock.fill")
                .font(.caption)
              Text(error.timestamp)
                .font(.caption)
                .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.red)
            .clipShape(Capsule())

            Spacer()

            // 위치 표시
            Text(error.who)
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(.red)
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .background(.red.opacity(0.1))
              .clipShape(Capsule())
          }

          // 문제점
          VStack(alignment: .leading, spacing: 4) {
            Text("문제")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Text(error.issue)
              .font(.body)
              .fontWeight(.semibold)
          }

          // 해결책
          VStack(alignment: .leading, spacing: 4) {
            Text("교정")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Text(error.fix)
              .font(.body)
              .foregroundStyle(.accentRedStrong)
          }
        }
        .padding()
        .background(.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(.red.opacity(0.2), lineWidth: 1)
        )
      }
    }
  }

  private func highlightSection(highlight: VisionFeedback.HighlightMoment) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "star.fill")
          .foregroundStyle(.yellow)
        Text("하이라이트")
          .font(.headline)
      }

      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 4) {
          Image(systemName: "clock.fill")
            .font(.caption)
          Text(highlight.timestamp)
            .font(.caption)
            .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.yellow)
        .clipShape(Capsule())

        Text(highlight.description)
          .font(.body)
      }
      .padding()
      .background(.yellow.opacity(0.05))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(.yellow.opacity(0.3), lineWidth: 1)
      )
    }
  }

  private func scoreColor(_ score: Double) -> Color {
    switch score {
    case 80...100: return .green
    case 60..<80: return .orange
    default: return .red
    }
  }

  private func scoreComment(_ score: Int) -> String {
    switch score {
    case 90...100: return "완벽해요!"
    case 80..<90: return "아주 좋아요!"
    case 70..<80: return "잘하고 있어요"
    case 60..<70: return "조금만 더!"
    default: return "연습이 필요해요"
    }
  }
}
