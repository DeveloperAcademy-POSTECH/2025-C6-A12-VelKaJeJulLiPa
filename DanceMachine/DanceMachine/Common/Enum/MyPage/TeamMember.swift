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
  case paidion
  case jacob
  case julianne
  case libby
  
  var imageName: String {
    switch self {
    case .velko: return "velko"
    case .kadan: return "kadan"
    case .paidion: return "paidion"
    case .jacob: return "jacob"
    case .julianne: return "julianne"
    case .libby: return "libby"
    }
  }
  
  var nameKor: String {
    switch self {
    case .velko: return "김진혁"
    case .kadan: return "조재훈"
    case .paidion: return "김준구"
    case .jacob: return "김경주"
    case .julianne: return "이주은"
    case .libby: return "배연경"
    }
  }
  
  var nameEng: String {
    switch self {
    case .velko: return "Velko"
    case .kadan: return "Kadan"
    case .paidion: return "Paidion"
    case .jacob: return "Jacob"
    case .julianne: return "Julianne"
    case .libby: return "Libby"
    }
  }
  
  var role: String {
    switch self {
    case .velko: return "iOS Developer"
    case .kadan: return "iOS Developer"
    case .paidion: return "iOS Developer"
    case .jacob: return "UI/UX Designer"
    case .julianne: return "UI/UX Designer"
    case .libby: return "Product Manager"
    }
  }
}
