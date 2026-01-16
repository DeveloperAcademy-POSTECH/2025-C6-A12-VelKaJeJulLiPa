//
//  Font.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

extension Font {
  enum Pretendard {
    case bold
    case semiBold
    case medium
    case regular
    
    var value: String {
      switch self {
      case .bold:
        return "Pretendard-Bold"
      case .semiBold:
        return "Pretendard-SemiBold"
      case .medium:
        return "Pretendard-Medium"
      case .regular:
        return "Pretendard-Regular"
      }
    }
  }
  
  enum EstablishRetrosans {
    case regular
    
    var value: String {
      switch self {
      case .regular:
        return "establishRetrosansOTF"
      }
    }
  }
  
  /// Pretendard 기본 생성 함수
  static func pretendard(_ weight: Pretendard, size: CGFloat) -> Font {
    .custom(weight.value, fixedSize: size)
  }
  
  /// Establish-RetroSans 기본 생성 함수
  static func establishRetrosans(_ weight: EstablishRetrosans, size: CGFloat) -> Font {
    .custom(weight.value, fixedSize: size)
  }
  
}

// MARK: - Design System Typography

/*
 예시 코드
 
 Text("타이틀")
   .font(.title1SemiBold)

 Text("본문 텍스트")
   .font(.body1Medium)
 
 */
extension Font {
  // Title
  static var title1SemiBold: Font {
    pretendard(.semiBold, size: 32)   // Title1/Semibold
  }
  
  static var title2SemiBold: Font {
    pretendard(.semiBold, size: 24)   // Title2/Semibold
  }
  
  // Heading
  static var heading1SemiBold: Font {
    pretendard(.semiBold, size: 18)   // Heading1/Semibold
  }
  
  static var heading1Medium: Font {
    pretendard(.medium, size: 18)     // Heading1/Medium
  }
  
  // Headline
  static var headline1Medium: Font {
    pretendard(.medium, size: 17)     // Headline1/Medium
  }
  
  static var headline2SemiBold: Font {
    pretendard(.semiBold, size: 16)   // Headline2/Semibold
  }
  
  static var headline2Medium: Font {
    pretendard(.medium, size: 16)     // Headline2/Medium
  }
  
  // Body
  static var body1Medium: Font {
    pretendard(.medium, size: 16)     // Body1/Medium (LH 160% -> Text에서 lineSpacing으로 조정)
  }
  
  // Footnote
  static var footnoteMedium: Font {
    pretendard(.medium, size: 14)     // Footnote/Medium
  }
  
  static var footnoteSemiBold: Font {
    pretendard(.semiBold, size: 14)   // Footnote/Semibold
  }
  
  // Caption
  static var caption1Medium: Font {
    pretendard(.medium, size: 12)     // Caption1/Medium
  }
}
