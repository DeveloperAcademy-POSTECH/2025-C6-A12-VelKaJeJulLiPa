//
//  InviteAcceptService.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import Foundation
import FirebaseFirestore

/// 초대 수락(검증 및 가입 처리) 서비스
/// - 역할:
///   1) 초대 토큰으로 invites 문서를 조회
///   2) 만료/상태 검증
///   3) Firestore 트랜잭션으로 `uses` 증가 및 사용자 팀스페이스 가입 처리
///   4) 가입 완료 후 teamspaceId 반환
// FIXME: - 하드 코딩 제거
// FIXME: - 싱글톤 인스턴스 활용하기
struct InviteAcceptService {

    // MARK: - 에러 정의
    enum AcceptError: Int {
        case notFound = 1        // 초대 문서를 찾지 못함
        case expired             // 만료됨
        case alreadyUsed         // 이미 사용됨(현재 로직은 미사용)
        case invalidStatus       // 상태가 pending 이 아님
        case invalidData         // 필드 구조가 올바르지 않음
        case alreadyMember       // 이미 해당 팀스페이스에 가입된 사용자
    }

    private func makeNSError(_ code: AcceptError, _ msg: String) -> NSError {
        NSError(
            domain: "InviteAcceptService",
            code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: msg]
        )
    }

    /// token으로 초대 검증 + 수락 처리
    /// - Parameters:
    ///   - token: 초대 토큰
    ///   - currentUserId: 현재 로그인한 사용자 ID
    /// - Returns: 가입될 teamspaceId
    func acceptInvite(
        token: String,
        currentUserId: String
    ) async throws -> String {
        let db = Firestore.firestore()

        // MARK: 1) token으로 초대 문서 조회
        print("➡️ [InviteAcceptService] 초대 수락 시작. token=\(token), user=\(currentUserId)")
        let snap = try await db.collection("invites")
            .whereField("token", isEqualTo: token)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else {
            print("❌ [InviteAcceptService] 초대 문서를 찾지 못했습니다.")
            throw makeNSError(.notFound, "Invite not found")
        }

        // MARK: 2) 문서에서 teamspaceId 등 1차 파싱
        let initial = doc.data()
        guard let teamspaceId = initial["teamspace_id"] as? String else {
            print("❌ [InviteAcceptService] 초대 문서 데이터가 올바르지 않습니다.(teamspace_id 없음)")
            throw makeNSError(.invalidData, "Invalid invite data")
        }
        print("🧩 [InviteAcceptService] 초대 문서 찾음. docId=\(doc.documentID), teamspaceId=\(teamspaceId)")

        // MARK: 3) 트랜잭션(검증 + 가입 처리)
        try await db.runTransaction({ (txn, errorPointer) -> Any? in
            do {
                // 최신 스냅샷으로 재검증
                let freshSnap = try txn.getDocument(doc.reference)
                guard let fresh = freshSnap.data() else {
                    errorPointer?.pointee = self.makeNSError(.notFound, "Invite not found")
                    print("❌ [InviteAcceptService] 트랜잭션: 초대 문서가 존재하지 않음")
                    return nil
                }

                let status    = (fresh["status"] as? String) ?? "pending"
                let uses      = (fresh["uses"] as? Int) ?? 0
                let expiresAt = (fresh["expires_at"] as? Timestamp)?.dateValue()

                print("""
                🔎 [InviteAcceptService] 트랜잭션 검증
                   - status=\(status)
                   - uses=\(uses)
                   - expiresAt=\(expiresAt?.description ?? "nil")
                """)

                // 만료 검증
                if let exp = expiresAt, exp < Date() {
                    errorPointer?.pointee = self.makeNSError(.expired, "Invite expired")
                    print("❌ [InviteAcceptService] 트랜잭션: 초대 링크 만료")
                    return nil
                }

                // 상태 검증
                if status != "pending" {
                    errorPointer?.pointee = self.makeNSError(.invalidStatus, "Invite is not pending")
                    print("❌ [InviteAcceptService] 트랜잭션: 초대 상태가 pending 이 아님(\(status))")
                    return nil
                }

                // 이미 가입 여부 확인: users/{uid}/user_teamspace/{teamspaceId}
                let userTeamRef = db.collection("users")
                    .document(currentUserId)
                    .collection("user_teamspace")
                    .document(teamspaceId)

                let existingUserTeam = try txn.getDocument(userTeamRef)
                if existingUserTeam.exists {
                    errorPointer?.pointee = self.makeNSError(.alreadyMember, "User already joined this teamspace")
                    print("⚠️ [InviteAcceptService] 트랜잭션: 이미 가입된 팀스페이스")
                    return nil
                }

                // uses 증가(필요 시 status 변경 로직 추가 가능)
                txn.updateData(["uses": uses + 1], forDocument: doc.reference)
                print("🔧 [InviteAcceptService] 트랜잭션: uses 증가 -> \(uses + 1)")

                // 사용자 user_teamspace 연결
                txn.setData([
                    "teamspace_id": teamspaceId,
                    "joined_at": FieldValue.serverTimestamp(),
                ], forDocument: userTeamRef, merge: true)
                print("🔗 [InviteAcceptService] 트랜잭션: users/\(currentUserId)/user_teamspace/\(teamspaceId) 설정")

                // 선택) teamspace/{id}/members/{uid} 문서 생성
                let memberRef = db.collection("teamspace")
                    .document(teamspaceId)
                    .collection("members")
                    .document(currentUserId)

                txn.setData([
                    "user_id": currentUserId,
                    "joined_at": FieldValue.serverTimestamp()
                ], forDocument: memberRef, merge: true)
                print("👥 [InviteAcceptService] 트랜잭션: teamspace/\(teamspaceId)/members/\(currentUserId)")

                return nil
            } catch {
                // 트랜잭션 블록 내부에서는 throw 대신 NSError로 세팅해야 함
                errorPointer?.pointee = error as NSError
                print("❌ [InviteAcceptService] 트랜잭션 내부 오류:", error.localizedDescription)
                return nil
            }
        })

        print("✅ [InviteAcceptService] 초대 수락 완료. teamspaceId=\(teamspaceId)")
        return teamspaceId
    }
}
