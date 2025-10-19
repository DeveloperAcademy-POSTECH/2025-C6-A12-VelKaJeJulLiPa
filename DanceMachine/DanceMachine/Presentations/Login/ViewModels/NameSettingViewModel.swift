//
//  NameSettingViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import Foundation
import Combine
import FirebaseAuth

@Observable
final class NameSettingViewModel {
    private let authManager = FirebaseAuthManager.shared
    private let storeManager = FirestoreManager.shared
    
    var displayName: String = ""
    
    init() {
        displayName = authManager.displayName(from: authManager.user?.displayName)
    }

    /// 사용자 이름을 업데이트하는 메서드
    /// - Parameters:
    ///     - name: 수정할 사용자 이름
    func updateUserName(name: String) async  {
        do {
            try await storeManager.updateFields(
                collection: .users,
                documentId: authManager.user?.uid ?? "",
                asDictionary: [ User.CodingKeys.name.stringValue: name ])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    ///  FirebaseAuthManager 의 needsNameSetting 값을 false 로 만드는 메서드
    ///  - needsNameSetting이 false가 되면 RootView 로 화면이 전환됩니다.
    func setNeedsNameSettingToFalse() {
        authManager.needsNameSetting = false
    }
}
