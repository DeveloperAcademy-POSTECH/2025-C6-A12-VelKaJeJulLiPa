//
//  InviteAcceptService.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import Foundation
import FirebaseFirestore

struct InviteAcceptService {
    enum AcceptError: Int {
        case notFound = 1
        case expired
        case invalidStatus
        case invalidData
        case alreadyMember
        case emptyUserId
    }
    
    private func makeNSError(_ code: AcceptError, _ msg: String) -> NSError {
        NSError(domain: "InviteAcceptService", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: msg])
    }
    
    func acceptInvite(token: String, currentUserId: String) async throws -> String {
        guard !token.isEmpty else { throw makeNSError(.invalidData, "Empty token") }
        guard !currentUserId.isEmpty else { throw makeNSError(.emptyUserId, "Empty currentUserId") }
        
        let db = Firestore.firestore()
        print("➡️ [InviteAcceptService] 초대 수락 시작. token=\(token), user=\(currentUserId)")
        
        let snap = try await db.collection("invites")
            .whereField("token", isEqualTo: token)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snap.documents.first else {
            throw makeNSError(.notFound, "Invite not found")
        }
        
        guard let teamspaceId = doc.data()["teamspace_id"] as? String else {
            throw makeNSError(.invalidData, "Invalid invite data (missing teamspace_id)")
        }
        
        try await db.runTransaction({ txn, errorPointer in
            do {
                let freshSnap = try txn.getDocument(doc.reference)
                guard let fresh = freshSnap.data() else {
                    errorPointer?.pointee = self.makeNSError(.notFound, "Invite not found")
                    return nil
                }
                
                let status = (fresh["status"] as? String) ?? "pending"
                let uses = (fresh["uses"] as? Int) ?? 0
                let expiresAt = (fresh["expires_at"] as? Timestamp)?.dateValue()
                
                if let exp = expiresAt, exp < Date() {
                    errorPointer?.pointee = self.makeNSError(.expired, "Invite expired")
                    return nil
                }
                if status != "pending" {
                    errorPointer?.pointee = self.makeNSError(.invalidStatus, "Invite is not pending")
                    return nil
                }
                
                let userTeamRef = db.collection("users")
                    .document(currentUserId)
                    .collection("user_teamspace")
                    .document(teamspaceId)
                
                if try txn.getDocument(userTeamRef).exists {
                    errorPointer?.pointee = self.makeNSError(.alreadyMember, "User already joined")
                    return nil
                }
                
                txn.updateData(["uses": uses + 1], forDocument: doc.reference)
                txn.setData([
                    "teamspace_id": teamspaceId,
                    "joined_at": FieldValue.serverTimestamp()
                ], forDocument: userTeamRef, merge: true)
                
                let memberRef = db.collection("teamspace")
                    .document(teamspaceId)
                    .collection("members")
                    .document(currentUserId)
                txn.setData([
                    "user_id": currentUserId,
                    "joined_at": FieldValue.serverTimestamp()
                ], forDocument: memberRef, merge: true)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        })
        
        print("✅ [InviteAcceptService] 초대 수락 완료. teamspaceId=\(teamspaceId)")
        return teamspaceId
    }
}
