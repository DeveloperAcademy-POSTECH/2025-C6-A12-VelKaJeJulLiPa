//
//  NameSettingViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import Foundation
import Combine
import FirebaseAuth

final class NameSettingViewModel: ObservableObject {
    private let authManager = FirebaseAuthManager.shared
    private let storeManager = FirestoreManager.shared
    
    @Published var displayName: String?
    
    init() {
        displayName = authManager.user?.displayName
    }
    
    /// 사용자 이름을 업데이트하는 메서드
    /// - Parameters:
    ///     - name: 수정할 사용자 이름
    func updateUserName(name: String) async throws {
        try await storeManager.updateFields(
            collection: .users,
            documentId: authManager.user?.uid ?? "",
            asDictionary: [ User.CodingKeys.name.stringValue : name ])
    }
    
    
    /// FIrebaseAuthManager 의 setHasName 값을 true 로 변경하는 메서드
    /// setHasName 가 true 로 변경되면, RootView 로 진입합니다.
    func setHasNameSet() {
        authManager.hasNameSet = true
    }
    
    /// UserDefaults의 hasNameSet 값을 true 로 변경하는 메서드
    /// 앱 종료 후 다시 진입할 때, 해당 값이 true 이면, 이름 설정 화면을 거치지 않고 RootView 로 진입합니다.
    func saveHasNameSetToUserDefaults() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasNameSet.rawValue)
    }
}
