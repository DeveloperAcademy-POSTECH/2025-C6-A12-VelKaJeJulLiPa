//
//  TipView.swift
//  DanceMachine
//
//  Created by 조재훈 on 12/16/25.
//

import Foundation
import SwiftUI
import TipKit

struct TeamspaceTip: Tip {
  @Parameter
  static var shouldshow: Bool = false
  
  var title: Text {
    Text("팀 스페이스를 만들어보세요!")
      .font(.headline)
      .foregroundStyle(Color.labelStrong)
  }
  
  var message: Text? {
    Text("팀만의 공간을 만들고 영상으로 피드백을 시작해 보세요.")
      .font(.subheadline)
      .foregroundStyle(Color.labelNormal)
  }
  
//  var image: Image? {
//    Image(.teamspaceTip)
////    Image(systemName: "person.2.fill")
//  }
  
  var rules: [Rule] {
    [
      #Rule(Self.$shouldshow) { $0 == true }
    ]
  }
  
  var options: [any TipOption] {
    [
      Tips.MaxDisplayCount(1)
    ]
  }
}

// MARK: - 프로젝트 추가 팁 (nonEmpty 상태, 설정 팁 다음)
struct AddProjectTip: Tip {
  //2번 팁이 닫힌 후에만 표시
  @Parameter
  static var isHomeViewReady: Bool = false

  var title: Text {
    Text("프로젝트를 추가해 보세요!")
      .font(.headline)
      .foregroundStyle(Color.labelStrong)
  }

  var message: Text? {
    Text("곡과 영상을 담을 수 있는 공간입니다.")
      .font(.subheadline)
      .foregroundStyle(Color.labelNormal)
  }

//  var image: Image? {
//    Image(.projectTip)
//  }
  
  var rules: [Rule] {
    [
      #Rule(Self.$isHomeViewReady) { $0 == true }
    ]
  }

  var options: [any TipOption] {
    [
      Tips.MaxDisplayCount(1)
    ]
  }
}


