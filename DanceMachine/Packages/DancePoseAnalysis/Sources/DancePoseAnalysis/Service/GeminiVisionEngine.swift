//
//  GeminiVisionEngine.swift
//  DancePoseAnalysis
//
//  Created by 조재훈 on 1/26/26.
//
//  Gemini 3 Vision API를 사용한 비디오 분석 엔진

import Foundation
import GoogleGenerativeAI

public final class GeminiVisionEngine {
  public static let shared = GeminiVisionEngine()
  private init() {}
  
  // GEMINI 3 Flash
  private lazy var model: GenerativeModel = {
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "APIKey") as? String else {
      fatalError("APIKey를 설정하세요")
    }
    
    let config = GenerationConfig(
      temperature: 0.7,
      topP: 0.95,
      topK: 40,
      maxOutputTokens: 16384,  // ✅ 충분한 출력 토큰
      responseMIMEType: "application/json"
    )
    
    return GenerativeModel(
      name: "gemini-3-flash-preview",  // ✅ Gemini 3 Flash (Preview)
      apiKey: apiKey,
      generationConfig: config
    )
  }()
  
  // MARK: - 비디오 분석
  
  /// GEMINI 3 Vision으로 단체 안무 분석
  /// - Parameters:
  ///   - fileURI: Gemini File API에서 받은 URI
  /// - Returns: VisionFeedback
  public func analyzeVideo(fileURI: String) async throws -> VisionFeedback {
    print("🎬 Gemini 3 Vision 분석 시작")

    // 1. 프롬프트 생성
    let prompt = buildPrompt()

    // 2. Gemini API 호출
    do {
      let response = try await model.generateContent(
          prompt,
          ModelContent.Part.fileData(mimetype: "video/quicktime", uri: fileURI)
      )

      // 3. JSON 파싱
      guard let text = response.text else {
        print("❌ Empty response from Gemini")
        print("📊 Candidates count: \(response.candidates.count)")

        if let firstCandidate = response.candidates.first {
          print("📊 Finish reason: \(String(describing: firstCandidate.finishReason))")
          print("📊 Safety ratings: \(firstCandidate.safetyRatings)")
        }

        throw GeminiVisionError.emptyResponse
      }

      print("✅ 응답 완료")
      print("📄 Response length: \(text.count) characters")

      // 토큰 사용량 로깅
      if let usageMetadata = response.usageMetadata {
        print("💰 Token usage:")
        print("   - Prompt tokens: \(usageMetadata.promptTokenCount)")
        print("   - Candidates tokens: \(usageMetadata.candidatesTokenCount)")
        print("   - Total tokens: \(usageMetadata.totalTokenCount)")
      }

      // 4. VisionFeedback로 디코딩
      let jsonData = text.data(using: .utf8)!
      let feedback = try JSONDecoder().decode(VisionFeedback.self, from: jsonData)

      return feedback

    } catch let error as GenerateContentError {
      print("❌ GenerateContentError: \(error)")
      print("❌ Error details: \(error.localizedDescription)")
      throw GeminiVisionError.apiError(error.localizedDescription)
    }
  }
  
  // MARK: - 프롬프트

  private func buildPrompt() -> String {
    return """
    Role: 너는 세계적인 아이돌 그룹의 퍼포먼스 디렉터이자 안무 감독이야.

    Task: 이 단체 안무 영상을 분석하고 교정 지시를 내려라.

    분석 관점:
    - 영상을 처음부터 끝까지 전 구간 시청하고, 단체 군무의 완성도를 해치는 사람과 동작 불일치를 찾아내줘

    피드백 스타일:
    - 기계적인 좌표값이 아니라, 관객이 봤을때 "어? 저 사람 좀 튀는데?" 라고 느낄법한 실루엣과 안무 틀림, 대형의 어긋남을 중심으로 분석해줘.
    - 사람의 눈으로 구분이 어려운 1초 미만의 차이는 무시하고, 확연히 박자가 빠르거나 느린 경우만 타임스탬프와 함께 적어줘.
    - 동작의 크기, 시선처리, 상체 하체 등 주변 멤버들과 조화롭지 않은 구간을 찾아줘
    - 전문적인 댄스 용어로 피드백 해줘.
    - **최대한 많은 교정 포인트를 찾아줘. 사소한 차이도 놓치지 마!**

    **위치 특정 방법:**
    - 왼쪽 오른쪽을 바꿔서 말해줘
    - 옷 색깔로 특정: "흰색 상의", "검은 바지", "빨간 셔츠"
    - 위치를 구체적으로: "중앙", "가장자리", "앞줄", "뒷줄"
    - 신체 특징이나 머리 스타일로 특정 가능

    규칙:
    - overall_score는 0-100점
    - critical_errors는 **최소 5개 이상, 최대 15개까지** 찾아줘
    - 타임스탬프 순서대로 정렬해줘
    - 같은 사람이 여러 구간에서 문제가 있으면 각각 따로 적어줘

    JSON 형식:
    {
      "overall_score": 75,
      "critical_errors": [
        {
          "timestamp": "00:03",
          "who": "흰색 상의",
          "issue": "시작 동작 타이밍 0.2초 늦음",
          "fix": "카운트 정확히 듣고 시작"
        },
        {
          "timestamp": "00:08",
          "who": "검은 바지",
          "issue": "팔 각도 15도 낮음, 익스텐션 부족",
          "fix": "어깨부터 끝까지 팔 완전히 펴기"
        },
        {
          "timestamp": "00:12",
          "who": "중앙 앞줄",
          "issue": "상체 숙임 각도 얕음, 90도 안됨",
          "fix": "허리 더 깊게 숙여서 바닥과 평행하게"
        },
        {
          "timestamp": "00:15",
          "who": "흰색 상의",
          "issue": "무릎 굽힘 부족, 다리 라인 안나옴",
          "fix": "플리에 깊게, 무릎 90도까지"
        },
        {
          "timestamp": "00:19",
          "who": "가장자리",
          "issue": "시선이 바닥으로 떨어짐",
          "fix": "정면 응시, 턱 들고 아이컨택 유지"
        },
        {
          "timestamp": "00:23",
          "who": "검은 바지",
          "issue": "체중 이동 느림, 반박자 늦음",
          "fix": "빠르게 반대쪽 발로 체중 옮기기"
        },
        {
          "timestamp": "00:28",
          "who": "중앙",
          "issue": "손목 스냅 없음, 각도 안나옴",
          "fix": "손목 90도 꺾어서 강조"
        },
        {
          "timestamp": "00:32",
          "who": "흰색 상의",
          "issue": "점프 높이 낮음, 타이밍도 빠름",
          "fix": "음악 정확히 맞춰서 더 높이 점프"
        }
      ],
      "highlight_moment": {
        "timestamp": "00:45",
        "description": "전체 에너지 통일감 좋음"
      }
    }

    중요:
    - analyzed_at 필드는 넣지 마세요 (자동 생성됨)
    - critical_errors가 없으면 빈 배열 []
    - highlight_moment가 없으면 null
    """
  }
}

enum GeminiVisionError: LocalizedError {
  case emptyResponse
  case apiError(String)

  var errorDescription: String? {
    switch self {
    case .emptyResponse: return "Gemini 응답이 비어있습니다 (Safety filter 또는 생성 실패)"
    case .apiError(let message): return "Gemini API 오류: \(message)"
    }
  }
}
