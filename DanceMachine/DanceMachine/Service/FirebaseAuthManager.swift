//
//  FirebaseAuthManager.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation

final class FirebaseAuthManager {
    
    static let shared = FirebaseAuthManager()
    
    private init() {}
    
    /// 현재 선택된 유저의 팀스페이스 입니다.
    var currentTeamspace: Teamspace?
}
