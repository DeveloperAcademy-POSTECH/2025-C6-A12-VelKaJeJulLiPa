//
//  NameSettingViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import Combine
import FirebaseAuth
import SwiftUI

@Observable
final class NameSettingViewModel {
  private let authManager = FirebaseAuthManager.shared
  private let storeManager = FirestoreManager.shared
  
  var isLoading: Bool = false
  
  var displayName: String = ""
  
  init() {
    displayName = authManager.displayName(from: authManager.user?.displayName)
  }
  
  /// 사용자 이름을 업데이트하는 메서드
  /// - Parameters:
  ///     - name: 수정할 사용자 이름
  func updateUserName(name: String) async throws {
    isLoading = true
    defer { isLoading = false }
    
    do {
      try await storeManager.updateFields(
        collection: .users,
        documentId: authManager.user?.uid ?? "",
        asDictionary: [User.CodingKeys.name.stringValue: name]
      )
    } catch {
      print(error.localizedDescription)
    }
  }
  
  
  func createNewuser() async throws {
    isLoading = true
    defer { isLoading = false }
    
    guard let userInfo = authManager.userInfo else {
      throw AuthenticationError.userNotFound
    }
    
    do {
      try await storeManager.createUser(userInfo)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  
  ///  - FirebaseAuthManager 의 authenticationState이 false가 되면 RootView 로 화면이 전환됩니다.
  func completeNameSetting() {
    authManager.completeAuthFlow()
  }
}
