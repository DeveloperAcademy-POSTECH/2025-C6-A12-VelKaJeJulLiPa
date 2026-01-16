//
//  TransactionManager.swift
//  DanceMachine
//
//  Created by Paidion on 11/14/25.
//

import Foundation
import FirebaseFirestore

/// Firestore 트랜잭션 전용 매니저
///
/// Firestore 트랜잭션(Transaction)은 여러 개의 작업(읽기/쓰기)을
/// **원자적(Atomic)** 으로 처리해야 하며, 데이터의 **정합성(Consistency)** 이
/// 중요한 상황에서 사용합니다.
///
/// 다시 말해, 작업이 모두 성공하거나 모두 실패해야하고,
/// 시스템 내 데이터가 서로 모순 없이 정확하고 일관된 상태를 유지하기 위해 트랜잭션을 사용합니다.
///
/// - 원자적(Atomic): 여러 작업을 하나의 단위로 묶어서, 전부 성공하거나 전부 실패하게 처리하는 것
///
/// # 언제 트랜잭션을 사용해야 하나?
/// 다음과 같은 경우 `Transaction`을 반드시 사용해야 합니다:
///
/// - **읽기 → 계산 → 쓰기 흐름이 필요한 경우**
///   - 예: 문서의 현재 값을 읽고, 그 값을 기반으로 증가/감소/변환한 후 다시 저장해야 하는 경우 (예: 좋아요 수 증가, 사용량 증가, 포인트 계산)
///
/// - **여러 사용자가 동시에 값을 업데이트할 가능성이 있는 경우**
///   - 예: 초대 코드 사용량 증가(uses += 1), 남은 쿠폰 개수 감소 등 동시 업데이트로 인한 데이터 충돌을 방지해야 하는 경우
///
/// # 중요
/// - 읽기(`get`) 작업이 반드시 쓰기 작업 이전에 실행되어야 합니다.
/// - 앱의 상태를 직접 수정하면 안됩니다.
/// - 트랜잭션은 Firestore가 **자동 재시도**합니다.
///   즉, 충돌이 감지되면 최신 데이터를 다시 읽고 로직을 재실행해 데이터 정합성을 보장합니다.
///
/// # 예시
/// 초대 코드 사용량 증가 처리
/// ```swift
/// try await TransactionManager.shared.perform { txn in
///     let snap = try txn.getDocument(inviteRef)
///     let uses = snap["uses"] as? Int ?? 0
///     txn.updateData(["uses": uses + 1], forDocument: inviteRef)
/// }
/// ```
///
///
final class TransactionManager {
  
  static let shared = TransactionManager()
  private init() {}
  
  private let db = Firestore.firestore()
  
  /// Firestore 트랜잭션을 실행하는 메서드입니다.
  ///
  /// - Parameter updateBlock:
  ///   트랜잭션 내에서 실행할 로직.
  ///   전달되는 `Transaction` 객체를 사용해 읽기(get)과 쓰기(set/update/detete) 작업을 수행합니다.
  ///
  /// - Throws:
  ///   트랜잭션 내부에서 발생한 오류.
  ///
  /// - Note:
  ///   Firestore는 충돌이 감지되면 트랜잭션을 자동으로 재시도합니다.
  func perform(_ updateBlock: @escaping (Transaction) throws -> Void) async throws {
    _ = try await db.runTransaction { transaction, errorPointer in
      do {
        try updateBlock(transaction)
        return nil
      } catch {
        errorPointer?.pointee = error as NSError
        return nil
      }
    }
  }
}
