//
//  VideoCompressionManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/12/25.
//

import Foundation
import AVFoundation

/// 비디오 압축 전용 매니저 입니다.
final class VideoCompressionManager {
  static let shared = VideoCompressionManager()
  private init() {}
  
  // 압축 설정 (테스트/유저 피드백에 따라 조절)
  struct CompressionConfig {
    // 해상도 제한
    let maxResolution: CGFloat = 1280  // 720p (1280x720)

    // 용량 제한 (3단계 체크)
    let targetFileSizeMB: Double = 50       // 목표: fileLengthLimit으로 압축 시도
    let maxOriginalFileSizeMB: Double = 500 // 압축 전: 원본이 이보다 크면 에러 (사전 차단)
    let maxCompressedFileSizeMB: Double = 80 // 압축 후: 결과물이 이보다 크면 에러 (targetFileSizeMB의 160%)

    // 용량 유지보수:
    // - targetFileSizeMB: 카톡 수준(30MB), 중간(50MB), 고화질(100MB)
    // - maxOriginalFileSizeMB: 너무 큰 영상 차단 (500MB, 1GB 등)
    // - maxCompressedFileSizeMB: targetFileSizeMB의 150-200% 권장 (fileLengthLimit 오차 고려)
  }
  
  private let config = CompressionConfig()
  
  /// 비디오를 필요시에만 검사하고 압축하는 메서드 입니다.
  /// - Parameters:
  ///   - asset: 원본 비디오 asset
  ///   - outputFileName: 출력 파일명 (확장자 제외하고)
  ///   - progressHandler: 압축 진행률 롤백 (ProgressManager 사용)
  /// - Returns: 압축된 파일 URL  (압출 불필요시 원본 URL을 반환합니다.)
  func compressIfNeeded(
    _ asset: AVURLAsset,
    outputFileName: String,
    progressHandler: @escaping (Double) -> Void
  ) async throws -> URL {
    // 1. 해상도 체크
    guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
      throw VideoError.compressionError
    }

    let naturalSize = try await videoTrack.load(.naturalSize)
    let width = naturalSize.width
    let height = naturalSize.height

    print("원본해상도: \(Int(width)) * \(Int(height))")

    // 2. 원본 파일 크기 체크
    let fileSize = try await getFileSize(asset.url)
    let fileSizeMB = Double(fileSize) / (1024 * 1024)
    print("원본 용량: \(String(format: "%.2f", fileSizeMB))MB")

    // 안전장치 1: 원본이 너무 크면 압축 시도조차 하지 않음 (시간 절약 & 실패 방지)
    if fileSizeMB > config.maxOriginalFileSizeMB {
      print("❌ 원본 용량 초과: \(String(format: "%.2f", fileSizeMB))MB > \(Int(config.maxOriginalFileSizeMB))MB")
      throw VideoError.fileTooLarge
    }

    // 3. 압축 필요 여부 판단
    let max = max(width, height)
    let targetSizeMB = config.targetFileSizeMB // 목표 용량 (fileLengthLimit과 동일)

    // 720p 이하이고 용량도 목표치 이하면 압축 스킵
    if max <= config.maxResolution && fileSizeMB <= targetSizeMB {
      print("압축 스킵: 720p 이하 + \(String(format: "%.0f", targetSizeMB))MB 이하")
      return asset.url
    }

    // 4. 압축 필요 (해상도가 크거나 용량이 큼)
    if max > config.maxResolution {
      print("해상도 압축 시작: \(Int(width))x\(Int(height)) → 720p")
    } else {
      print("용량 압축 시작: \(String(format: "%.2f", fileSizeMB))MB → \(String(format: "%.0f", targetSizeMB))MB (비트레이트 조정)")
    }

    // compress() 메서드로 실제 압축 진행
    // - fileLengthLimit으로 목표 용량 설정
    // - 압축 후 validatedFileSize()로 최종 검증
    return try await compress(
      asset,
      outputFileName: outputFileName,
      progressHandler: progressHandler
    )
  }
  
  /// 실제 압축 메서드 입니다.
  private func compress(
    _ asset: AVURLAsset,
    outputFileName: String,
    progressHandler: @escaping (Double) -> Void
  ) async throws -> URL {
    let outputURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(outputFileName)_compressed.mp4")

    // 기존 파일 삭제
    if FileManager.default.fileExists(atPath: outputURL.path) {
      try? FileManager.default.removeItem(at: outputURL)
    }

    // 애플이 제공하는 프리셋 사용
    // 720p 해상도로 압축
    guard let exportSession = AVAssetExportSession(
      asset: asset,
      presetName: AVAssetExportPreset1280x720
    ) else {
      throw VideoError.compressionError
    }

    exportSession.shouldOptimizeForNetworkUse = true
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4

    // fileLengthLimit 설정: 시스템이 자동으로 비트레이트 조정하여 목표 용량에 맞춤
    // 목표치보다 10-60% 초과 가능 (예: 50MB → 45-80MB)
    exportSession.fileLengthLimit = Int64(config.targetFileSizeMB * 1024 * 1024)
    print("압축 목표: \(String(format: "%.0f", config.targetFileSizeMB))MB (실제 결과는 오차 범위 있음)")

    // 진행률 모니터링
    let monitoringTask = Task {
      while !Task.isCancelled {
        let progress = await MainActor.run {
          return exportSession.progress
        }
        progressHandler(Double(progress))

        if progress >= 1.0 {
          break
        }
        try? await Task.sleep(for: .milliseconds(100))
      }
    }

    // 압축 실행
    do {
      try await exportSession.export(to: outputURL, as: .mp4)
      monitoringTask.cancel()
      print("압축 완료!")
      try validatedFileSize(outputURL)
      return outputURL
    } catch let error as VideoError {
      monitoringTask.cancel()
      print("용량 초과로 압축 거부~")
      try? FileManager.default.removeItem(at: outputURL)
      throw error
    } catch {
      monitoringTask.cancel()
      print("압축 실패...")
      try? FileManager.default.removeItem(at: outputURL)
      throw VideoError.compressionError
    }
  }
  
  /// 파일 크기 검증하는 메서드입니다.
  /// 안전장치 2: 압축 후 최종 용량 체크 (fileLengthLimit이 정확하지 않으므로 필수)
  private func validatedFileSize(_ url: URL) throws {
    let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
    let fileSizeMB = Double(fileSize) / (1024 * 1024)

    print("압축 완료: \(String(format: "%.2f", fileSizeMB))MB")

    // 최대 허용 용량 초과 여부 체크
    if fileSizeMB > config.maxCompressedFileSizeMB {
      print("압축 후 용량 초과: \(String(format: "%.2f", fileSizeMB))MB > \(Int(config.maxCompressedFileSizeMB))MB")
      try? FileManager.default.removeItem(at: url)
      throw VideoError.fileTooLarge
    }

    print("최종 통과: \(String(format: "%.2f", fileSizeMB))MB ≤ \(Int(config.maxCompressedFileSizeMB))MB")
  }
  
  /// 원본 파일 크기를 가져오는 메서드입니다.
  private func getFileSize(_ url: URL) async throws -> UInt64 {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return attributes[.size] as? UInt64 ?? 0
  }
  
  /// 저장되었던 임시파일 삭제하는 메서드입니다.
  func deleteTempFile(_ url: URL) {
    if url.path.contains("_compressed.mp4") {
      try? FileManager.default.removeItem(at: url)
      print("압축 성공 후 저장되었던 캐시파일 삭제")
    }
  }
}
