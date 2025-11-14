//
//  Date+.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import Foundation


extension Date {
    
    func formattedDate() -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "yyyy년 MM월 dd일"
       return formatter.string(from: self)
     }
    
    private static let cachedDateFormatter: DateFormatter = {
          let f = DateFormatter()
          return f
      }()
    
    /// 특정 시각이 현재 시각으로부터 5분을 넘었는지 판별하는 메서드
    func isWithinPast(minutes: Int) -> Bool {
        let now = Date.now
        let timeAgo = Date.now.addingTimeInterval(-1 * TimeInterval(60 * minutes))
        let range = timeAgo...now
        return range.contains(self)
    }
    
    
    // MARK: - 1분 미만=방금 전, 1주 이내=상대시간, 그 외 = 날짜
    func listTimeLabel(now: Date = .now) -> String {
        let diff = now.timeIntervalSince(self)
        
        if diff < 0 { return "방금 전" }
        
        // 1분 미만
        if diff < 60 {
            return "방금 전"
        }
        
        // 1주 이내는 상대 시간
        if diff < 7 * 24 * 60 * 60 {
            let r = RelativeDateTimeFormatter()
            r.locale = Locale(identifier: "ko_KR")
            r.unitsStyle = .full           // "13분 전", "1시간 전", "어제"
            r.calendar = Calendar(identifier: .gregorian)
            return r.localizedString(for: self, relativeTo: now)
        }
        
        // 1주 초과: 같은 해면 "M월 d일", 해가 다르면 "yyyy. M. d."
        let cal = Calendar.current
        let sameYear = cal.component(.year, from: self) == cal.component(.year, from: now)
        
        let df = Date.cachedDateFormatter
        df.locale = .current
        df.dateFormat = sameYear ? "M월 d일" : "yyyy. M. d."
        return df.string(from: self)
    }
  
  // ISO8601 (KST, 밀리초 포함)
  /// 캐싱을 위한 밀리초 까지 계산 메서드
     func iso8601KST() -> String {
         let iso = ISO8601DateFormatter()
         iso.timeZone = .kst
         iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
         return iso.string(from: self)
     }
}


extension TimeZone {
    static let kst = TimeZone(identifier: "Asia/Seoul")!
}

