//
//  BatchManager.swift
//  DanceMachine
//
//  Created by Paidion on 11/15/25.
//

import Foundation
import FirebaseFirestore

/// Firestore Batch 전용 매니저
///
/// Batch는 여러 개의 쓰기 작업(set/update/delete)을
/// **원자적(Atomic)** 으로 처리할 때 사용합니다.
///
/// 다시 말해, 묶인 모든 작업이 **모두 성공하거나 모두 실패하게** 처리되므로
/// 여러 문서를 한 번에 안전하게 변경해야 할 때 유용합니다.
///
/// - 원자적(Atomic): 여러 쓰기 작업을 하나의 단위로 묶어 부분 성공이 없도록 하는 것
///
/// # 언제 Batch를 사용해야 하나?
/// 다음과 같은 경우 `Batch`를 사용하면 좋습니다:
///
/// - **여러 문서를 읽을 필요 없이, 단순히 여러 문서를 동시에 수정/삭제해야 하는 경우**
///   - 예: 여러 문서를 한 번에 업데이트, 여러 필드를 동시에 삭제하는 경우
///
/// - **동시성 충돌 위험이 적고 단순 쓰기 작업만 필요한 경우**
///   - 예: 알림 문서 삭제 + 유저 알림 문서 삭제 등
///
/// # 중요
/// - Batch는 `읽기(get)`를 지원하지 않습니다.
///   오직 set/update/delete 기반의 쓰기 작업만 가능합니다.
/// - Batch는 트랜잭션처럼 자동 재시도는 하지 않습니다.
/// - Batch는 “모두 성공 / 모두 실패”를 보장하여 데이터 정합성을 유지합니다.
///
/// # 예시
/// 두 문서를 한꺼번에 삭제하는 경우
/// ```swift
/// try await BatchManager.shared.perform { batch in
///     batch.deleteDocument(notificationRef)
///     batch.deleteDocument(userNotificationRef)
/// }
/// ```
///
final class BatchManager {
    
    static let shared = BatchManager()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// Firestore WriteBatch를 실행하는 메서드입니다.
    ///
    /// - Parameter block:
    ///   Batch 작업을 구성하는 클로저.
    ///   전달된 `WriteBatch` 객체를 사용해 set/update/delete 작업을 추가합니다.
    ///
    /// - Throws:
    ///   batch 내부에서 발생한 오류 또는 commit 시 발생한 오류.
    ///
    /// - Note:
    ///   Batch는 읽기 작업을 지원하지 않으며, 모든 쓰기 작업은 commit 시점에 한 번에 처리됩니다.
    func perform(_ block: (WriteBatch) throws -> Void) async throws {
        let batch = db.batch()
        
        do {
            try block(batch)         // 여러 문서의 쓰기 작업 추가
            try await batch.commit() // 모두 성공하거나, 하나라도 실패하면 전체 실패
        } catch {
            throw error
        }
    }
}
