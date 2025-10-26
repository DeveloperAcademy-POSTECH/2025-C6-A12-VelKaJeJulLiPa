//
//  EditNameViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import Foundation

@Observable
final class EditNameViewModel {
    
    var myName: String { FirebaseAuthManager.shared.userInfo?.name ?? "Unknown" }
 
    /// 사용자 이름을 업데이트 하는 메서드 입니다.
    /// - Parameters:
    ///     - userId: 사용자 Id
    ///     - newName: 변경할 이름
    func updateMyNameAndReload(userId: String, newName: String) async throws {
        do {
            try await FirestoreManager.shared.updateFields(
                collection: .users,
                documentId: userId,
                asDictionary: [ User.CodingKeys.name.rawValue: newName ]
            )
            
            // 조회 후 값 다시 넣어주기
            FirebaseAuthManager.shared.userInfo = try await FirestoreManager.shared.get(
                userId,
                from: .users
            )
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
        }
    }
}
