//
//  GeminiFileManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 1/26/26.
//

import Foundation

public actor GeminiFileManager {
  public static let shared = GeminiFileManager()
  private init() {}

  private let baseURL = "https://generativelanguage.googleapis.com"
  private var apiKey: String {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "APIKey") as? String else {
      fatalError("APIKey를 설정하세요")
    }
    return key
  }

  // MARK: - 1. 비디오 업로드

  /// 비디오 업로드 파일을 Gemini File API에 업로드 (Resumable Upload)
  /// - Parameter videoURL: 로컬 비디오 파일 URL
  /// - Returns: Gemini File URI (예: "https://generativelanguage.googleapis.com/v1beta/files/abc123")
  public func uploadVideo(_ videoURL: URL) async throws -> String {
    print("🚀 Uploading video to Gemini (Resumable Upload)...")

    let videoData = try Data(contentsOf: videoURL)
    print("📦 Video size: \(Double(videoData.count) / 1024 / 1024) MB")

    // STEP 1: Start resumable upload
    print("📤 Step 1: Starting upload...")
    let uploadURL = try await startResumableUpload(fileSize: videoData.count)
    print("✅ Upload URL received: \(uploadURL)")

    // STEP 2: Upload video data
    print("📤 Step 2: Uploading video data...")
    let fileURI = try await uploadVideoData(uploadURL: uploadURL, videoData: videoData)
    print("✅ Upload complete: \(fileURI)")

    // STEP 3: Wait for file to be ACTIVE
    print("⏳ Step 3: Waiting for file to be processed...")
    try await waitForFileActive(fileName: fileURI)
    print("✅ File is ready!")

    return fileURI
  }

  // STEP 1: Start resumable upload
  private func startResumableUpload(fileSize: Int) async throws -> String {
    var request = URLRequest(url: URL(string: "\(baseURL)/upload/v1beta/files")!)
    request.httpMethod = "POST"
    request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
    request.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
    request.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
    request.setValue("video/quicktime", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
    request.setValue("\(fileSize)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200,
          let uploadURL = httpResponse.value(forHTTPHeaderField: "X-Goog-Upload-URL") else {
      throw GeminiFileError.uploadFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    return uploadURL
  }

  // STEP 2: Upload video data
  private func uploadVideoData(uploadURL: String, videoData: Data) async throws -> String {
    var request = URLRequest(url: URL(string: uploadURL)!)
    request.httpMethod = "POST"
    request.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
    request.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
    request.httpBody = videoData

    // 타임아웃 설정 (큰 파일용)
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 300  // 5분
    let session = URLSession(configuration: config)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw GeminiFileError.uploadFailed(statusCode: 0)
    }

    print("📡 Upload response status: \(httpResponse.statusCode)")

    if httpResponse.statusCode != 200 {
      if let errorText = String(data: data, encoding: .utf8) {
        print("❌ Error: \(errorText)")
      }
      throw GeminiFileError.uploadFailed(statusCode: httpResponse.statusCode)
    }

    // Parse file URI
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let file = json?["file"] as? [String: Any],
          let uri = file["uri"] as? String else {
      throw GeminiFileError.invalidResponse
    }

    return uri
  }
  
  // MARK: - 2. 파일 상태 확인
  
  /// 파일이 ACTIVE 상태가 될 때까지 대기
  private func waitForFileActive(fileName: String) async throws {
    // fileName: "https://generativelanguage.googleapis.com/v1beta/files/xxx"
    // URL에서 경로 추출
    let path = fileName.replacingOccurrences(of: "\(baseURL)/v1beta/", with: "")

    for attempt in 1...30 {
      let state = try await getFileState(fileName: path)

      if state == "ACTIVE" {
        print("✅ File is ACTIVE")
        return
      }

      print("⏳ File state: \(state), attempt \(attempt)/30")
      try await Task.sleep(nanoseconds: 1_000_000_000)  // 1초 대기
    }

    throw GeminiFileError.fileNotReady
  }

  /// 파일 상태 조회
  private func getFileState(fileName: String) async throws -> String {
    let url = URL(string: "\(baseURL)/v1beta/\(fileName)?key=\(apiKey)")!
    let (data, _) = try await URLSession.shared.data(from: url)

    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    return json?["state"] as? String ?? "UNKNOWN"
  }
}


public enum GeminiFileError: LocalizedError {
  case uploadFailed(statusCode: Int)
  case invalidResponse
  case fileNotReady

  public var errorDescription: String? {
    switch self {
    case .uploadFailed(let code): return "비디오 업로드 실패 (HTTP \(code))"
    case .invalidResponse: return "잘못된 응답"
    case .fileNotReady: return "파일 처리 시간 초과"
    }
  }
}
