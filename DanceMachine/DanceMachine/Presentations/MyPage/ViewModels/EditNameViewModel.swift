//
//  EditNameViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import Foundation

@Observable
final class EditNameViewModel {
  
  var isLoading: Bool = false
  var myName: String { FirebaseAuthManager.shared.userInfo?.name ?? "Unknown" }
  
  var showErrorMessage: Bool = false
  
  /// 사용자 이름 업데이트 (에러를 뷰모델 내부에서 처리)
  func updateMyNameAndReload(userId: String, newName: String) async -> Bool {
    isLoading = true
    defer { isLoading = false }
    
    do {
      try await FirestoreManager.shared.updateFields(
        collection: .users,
        documentId: userId,
        asDictionary: [ User.CodingKeys.name.rawValue: newName ]
      )
      
      FirebaseAuthManager.shared.userInfo = try await FirestoreManager.shared.get(
        userId,
        from: .users
      )
  
      return true

    } catch {
      showErrorMessage = true
      print("error: \(error.localizedDescription)")
      return false
    }
  }
}
