//
//  FirestoreManager.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/2/25.
//

import FirebaseFirestore
import FirebaseSharedSwift

final class FirestoreManager {
    
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    private init() {}
    

    @discardableResult
    private func save<T: EntityRepresentable>(
        _ data: T,
        strategy: WriteStrategy
    ) async throws -> T {
        
        guard var dict = data.asDictionary else { throw FirestoreError.encodingFailed }
        
        // - create: created_at + updated_at
        // - update: updated_at
        // - join: joined_at
        switch strategy {
        case .join:
            dict[strategy.rawValue] = FieldValue.serverTimestamp()
        case .create:
            dict[strategy.rawValue] = FieldValue.serverTimestamp()
            dict[WriteStrategy.update.rawValue] = FieldValue.serverTimestamp()
        case .update:
            dict[strategy.rawValue] = FieldValue.serverTimestamp()
        case .userStrategy:
            dict[WriteStrategy.create.rawValue] = FieldValue.serverTimestamp()
            dict[WriteStrategy.update.rawValue] = FieldValue.serverTimestamp()
            dict[WriteStrategy.userStrategy.rawValue] = FieldValue.serverTimestamp()
        case .userUpdateStrategy:
            dict[WriteStrategy.userStrategy.rawValue] = FieldValue.serverTimestamp()
        }
        
        let ref = db
                    .collection(data.entityName.rawValue)
                    .document(data.documentID)
        
        switch strategy {
        case .create:
            try await ref.setData(dict)
        case .update:
            try await ref.updateData(dict)
        case .join:
            try await ref.setData(dict)
        case .userStrategy:
            try await ref.setData(dict)
        case .userUpdateStrategy:
            try await ref.updateData(dict)
        }
        
        return data
    }
    
    @discardableResult
    func create<T: EntityRepresentable>(_ data: T) async throws -> T {
        try await save(data, strategy: .create)
    }
    
    @discardableResult
    func update<T: EntityRepresentable>(_ data: T) async throws -> T {
        try await save(data, strategy: .update)
    }
    
    @discardableResult
    func createJoin<T: EntityRepresentable>(_ data: T) async throws -> T {
        try await save(data, strategy: .join)
    }
    
    // TODO: 코드 논의
    @discardableResult
    func createUser<T: EntityRepresentable>(_ data: T) async throws -> T {
        try await save(data, strategy: .userStrategy)
    }
    
    // TODO: 코드 논의
    @discardableResult
    func updateUserLastLogin<T: EntityRepresentable>(_ data: T) async throws -> T {
        try await save(data, strategy: .userUpdateStrategy)
    }
    
    /// 컬렉션의 데이터를 가져옵니다.
    /// - id: documentID
    /// - type: 컬렉션 타입
    func get<T: Decodable>(
        _ id: String,
        from type: CollectionType
    ) async throws -> T {
        let snapshot = try await db.collection(type.rawValue).document(id).getDocument()
        guard let data = try? snapshot.data(as: T.self) else {
            throw FirestoreError.fetchFailed(
                underlying: NSError(
                    domain: "", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "문서가 존재하지 않습니다."]
                )
            )
        }
        return data
    }
    
    /// 컬렉션의 모든 데이터를 가져옵니다.
    /// 파이어베이스 색인으로 정렬합니다.
    /// - id: userID
    /// - type: 컬렉션 타입
    /// - key: 컬렉션 안의 문서의 대한 조건절
    /// - orderKey: 어느 기준으로 정렬
    /// - descending: 정렬 방향
    @discardableResult
    func fetchAll<T: Decodable>(
        _ id: String,
        from type: CollectionType,
        where key: String,
        orderBy orderKey: String? = nil,
        descending: Bool = true
    ) async throws -> [T] {
        var query: Query = db.collection(type.rawValue).whereField(key, isEqualTo: id)
        if let orderKey { query = query.order(by: orderKey, descending: descending) }
        let snap = try await query.getDocuments()
        return snap.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    
    /// 특정 부모 문서 하위의 서브컬렉션을 가져옵니다.
    /// - Parameters:
    ///   - parentType: 부모 컬렉션(.user 등)
    ///   - parentId: 부모 문서 ID(userId 등)
    ///   - subType: 서브컬렉션(.blocks 등)
    ///   - orderKey: 정렬 기준(옵션)
    ///   - descending: 정렬 방향
    @discardableResult
    func fetchAllFromSubcollection<T: Decodable>(
        under parentType: CollectionType,
        parentId: String,
        subCollection subType: CollectionType,
        orderBy orderKey: String? = nil,
        descending: Bool = true
    ) async throws -> [T] {
        var q: Query = db
            .collection(parentType.rawValue)
            .document(parentId)
            .collection(subType.rawValue)
        
        if let orderKey {
            q = q.order(by: orderKey, descending: descending)
        }
        
        let snap = try await q.getDocuments()
        return snap.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    func delete(collectionType: CollectionType, documentID: String) async throws {
        try await db
            .collection(collectionType.rawValue)
            .document(documentID)
            .delete()
    }
    
    /// 특정 부모 문서 하위의 서브컬렉션을 가져옵니다.
    /// - Parameters:
    ///   - parentType: 부모 컬렉션(.user 등)
    ///   - parentId: 부모 문서 ID(userId 등)
    ///   - subType: 서브컬렉션(.blocks 등)
    ///   - documentID: 삭제 문서(삭제 하려는 user_id)
    func deleteFromSubcollection(
        under parentType: CollectionType,
        parentId: String,
        subCollection subType: CollectionType,
        target documentID: String
    ) async throws {
        try await db
            .collection(parentType.rawValue)
            .document(parentId)
            .collection(subType.rawValue)
            .document(documentID)
            .delete()
    }
    
}
