//
//  TeamMember.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import SwiftUI

enum TeamMember: CaseIterable {
  case velko
  case kadan
  case jacob
  case julianne
  case libby
  case paidion
  
  var imageName: String {
    switch self {
    case .velko: return "Velko"
    case .kadan: return "Kadan"
    case .jacob: return "Jacob"
    case .julianne: return "Julianne"
    case .libby: return "Libby"
    case .paidion: return "Paidion"
    }
  }
  
  var nameKor: String {
    switch self {
    case .velko: return "벨코"
    case .kadan: return "카단"
    case .jacob: return "제이콥"
    case .julianne: return "줄리엔"
    case .libby: return "리비"
    case .paidion: return "파이디온"
    }
  }
  
  var nameEng: String {
    switch self {
    case .velko: return "Velko"
    case .kadan: return "Kadan"
    case .jacob: return "Jacob"
    case .julianne: return "Julianne"
    case .libby: return "Libby"
    case .paidion: return "Paidion"
    }
  }
  
  var role: String { //FIXME: 문구 Hi-fi 반영
    switch self {
    case .velko: return "iOS Developer"
    case .kadan: return "iOS Developer"
    case .jacob: return "UI/UX Designer"
    case .julianne: return "UI/UX Designer"
    case .libby: return "Product Manager"
    case .paidion: return "iOS Developer"
    }
  }

  var description: String { //FIXME: 필요 여부 판단 후 수정 혹은 삭제
    switch self {
    case .velko: return "Velko"
    case .kadan: return "Kadan"
    case .jacob: return "Jacob"
    case .julianne: return "Julianne"
    case .libby: return "Libby"
    case .paidion: return "Paidion"
    }
  }
  
  var backgroundColor: Color { //FIXME: 이미지 배경색 수정
    switch self {
    case .velko: return .gray.opacity(0.2)
    case .kadan: return .gray.opacity(0.2)
    case .jacob: return .gray.opacity(0.2)
    case .julianne: return .gray.opacity(0.2)
    case .libby: return .gray.opacity(0.2)
    case .paidion: return .gray.opacity(0.2)
    }
  }
}
