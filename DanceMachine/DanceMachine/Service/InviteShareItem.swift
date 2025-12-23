//
//  InviteShareItem.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import UIKit
import LinkPresentation

/// 초대 링크를 공유할 때, `UIActivityViewController`에 전달할 텍스트/메타데이터를 제공하는 아이템 소스입니다.
/// 팀 이름과 초대 URL을 조합해 공유 본문/제목/미리보기 정보를 구성합니다.
final class InviteShareItem: NSObject, UIActivityItemSource {
  /// 초대를 보낸 팀 스페이스 이름
  let teamName: String
  /// 초대 유니버설 링크(URL)
  let url: URL
  
  /// 초대 공유 아이템 초기화
  /// - Parameters:
  ///   - teamName: 팀 스페이스 이름
  ///   - url: 초대 유니버설 링크
  init(teamName: String, url: URL) {
    self.teamName = teamName
    self.url = url
  }
  
  /// 공유 시트가 표시되기 전에 사용되는 플레이스홀더(미리보기용) 아이템을 반환합니다.
  /// URL 객체만 반환하여 메타데이터(링크 카드)에 의존합니다.
  func activityViewControllerPlaceholderItem(
    _ activityViewController: UIActivityViewController
  ) -> Any {
    return url
  }
  
  /// 실제 공유 대상 앱(카톡/메시지/메일 등)에 전달할 아이템을 반환합니다.
  /// URL 객체만 반환하여 링크 메타데이터(카드)를 우선 사용하도록 합니다.
  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    return url
  }
  
  /// 메일 공유 등에서 제목(Subject)으로 사용될 텍스트를 제공합니다.
  func activityViewController(
    _ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    return "[\(teamName)] 팀 초대"
  }
  
  /// 링크 미리보기(메타데이터)를 제공합니다.
  /// 공유 시트/일부 앱에서 링크 카드의 제목/URL 미리보기로 활용됩니다.
  func activityViewControllerLinkMetadata(
    _ activityViewController: UIActivityViewController
  ) -> LPLinkMetadata? {
    let md = LPLinkMetadata()
    // 제목에 설명 포함
    md.title = "DirAct - [\(teamName)] 팀 초대"
    md.originalURL = url
    md.url = url
    
    if let icon = UIImage(named: "appIcon") {
      md.iconProvider = NSItemProvider(object: icon)
    }
    
    return md
  }
}
