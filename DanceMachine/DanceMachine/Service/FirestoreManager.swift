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
        case .invite:
            dict[WriteStrategy.create.rawValue] = FieldValue.serverTimestamp()
            let oneDayLater = Date().addingTimeInterval(60 * 60 * 24)
            dict[strategy.rawValue] = Timestamp(date: oneDayLater)
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
        case .invite:
            try await ref.setData(dict)
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
    
    // TODO: 코드 논의
    @discardableResult
    func createInvite<T: EntityRepresentable>(_ data: T) async throws -> T {
        try await save(data, strategy: .invite)
    }
    
    /// 특정 필드만 부분 업데이트를 진행하는 메서드입니다.
    /// - Parameters:
    ///     - collection: 컬렉션 타입
    ///     - documentId: 변경하고자 하는 documentId
    ///     - asDictionary: 변경하려는 딕셔너리 데이터
    func updateFields(
        collection: CollectionType,
        documentId: String,
        asDictionary: [String: Any]
    ) async throws {
        var asDictionary = asDictionary
        asDictionary[WriteStrategy.update.rawValue] = FieldValue.serverTimestamp() // 업데이트 시간을 포함
        
        try await db
            .collection(collection.rawValue)
            .document(documentId)
            .updateData(asDictionary)
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
  
      /// 서브컬렉션의 데이터를 생성합니다.
      /// - Parameters:
      ///     - data: 데이터 형태
      ///     - under: 부모 컬렉션 타입
      ///     - parentId: document 이름
      ///     - subCollection: 서브 컬렉션 타입
      ///     - strategy: 전략 타입 (join, create, update, userStrategy)
      @discardableResult
      func createToSubcollection<T: EntityRepresentable>(
          _ data: T,
          under parentType: CollectionType,
          parentId: String,
          subCollection subType: CollectionType,
          strategy: WriteStrategy
      ) async throws -> T {
          guard var dict = data.asDictionary else { throw FirestoreError.encodingFailed }
        
        // 타임스탬프 처리 (save와 동일한 규칙)
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
        case .invite:
            dict[WriteStrategy.create.rawValue] = FieldValue.serverTimestamp()
            dict[strategy.rawValue] = Date().addingTimeInterval(60 * 60 * 24)
        }

          let ref = db
              .collection(parentType.rawValue)
              .document(parentId)
              .collection(subType.rawValue)
              .document(data.documentID)

        switch strategy {
        case .create, .join, .userStrategy:
            try await ref.setData(dict)
        case .update, .userUpdateStrategy:
            try await ref.updateData(dict)
        case .invite:
            try await ref.setData(dict)
        }
          return data
      }
  
      /// 서브서브컬렉션의 데이터를 생성합니다.
      /// - Parameters:
      ///     - data: 데이터 형태
      ///     - in: 상위 부모 컬렉션 타입 ex) Tracks
      ///     - grandParentId: document 이름
      ///     - withIn 부모 컬렉션 타입 ex) Section
      ///     - parentId: document 이름
      ///     - subCollection: 서브 컬렉션 타입
      ///     - strategy: 전략 타입 (join, create, update, userStrategy)
      @discardableResult
      func createToSubSubcollection<T: EntityRepresentable>(
          _ data: T,
          in grandParentType: CollectionType,
          grandParentId: String,
          withIn parentType: CollectionType,
          parentId: String,
          subCollection subType: CollectionType,
          strategy: WriteStrategy
      ) async throws -> T {
          guard var dict = data.asDictionary else { throw FirestoreError.encodingFailed }

          // 타임스탬프 처리 (save와 동일한 규칙)
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
          case .invite:
              dict[WriteStrategy.create.rawValue] = FieldValue.serverTimestamp()
              dict[strategy.rawValue] = Date().addingTimeInterval(60 * 60 * 24)
          }

          let ref = db
              .collection(grandParentType.rawValue)
              .document(grandParentId)
              .collection(parentType.rawValue)
              .document(parentId)
              .collection(subType.rawValue)
              .document(data.documentID)

          switch strategy {
          case .create, .join, .userStrategy:
              try await ref.setData(dict)
          case .update, .userUpdateStrategy:
              try await ref.updateData(dict)
          case .invite:
              try await ref.setData(dict)
          }

          return data
      }
  
    /// 컬렉션의 모든 데이터를 가져옵니다.
    /// 파이어베이스 색인으로 정렬합니다.
    /// - Parameters:
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
    /// 특정 부모 문서 하위의 서브컬렉션을 가져옵니다.
    /// - Parameters:
    ///   - parentType: 부모 컬렉션(.user 등)
    ///   - parentId: 부모 문서 ID(userId 등)
    ///   - subType: 서브컬렉션(.blocks 등)
    ///   - orderKey: 정렬 기준(옵션)
    ///   - descending: 정렬 방향
    @discardableResult
    func fetchAllFromSubSubcollection<T: Decodable>(
        in grandParentType: CollectionType,
        grandParentId: String,
        withIn parentType: CollectionType,
        parentId: String,
        subCollection subType: CollectionType,
        orderBy orderKey: String? = nil,
        descending: Bool = true
    ) async throws -> [T] {
        var q: Query = db
            .collection(grandParentType.rawValue)
            .document(grandParentId)
            .collection(parentType.rawValue)
            .document(parentId)
            .collection(subType.rawValue)
      
        if let orderKey {
            q = q.order(by: orderKey, descending: descending)
        }
      
        let snap = try await q.getDocuments()
        return snap.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    //TODO: 범용적으로 사용할 수 있도록 리팩토링
    @discardableResult
    func fetchNotificationList<T: Decodable>(
        userId: String,
        currentTeamspaceId: String,
        from type: CollectionType = .notification,
        where receiverIds: String = Notification.CodingKeys.receiverIds.rawValue,
        teamspaceField: String = Notification.CodingKeys.teamspaceId.rawValue,
        orderBy orderKey: String = Notification.CodingKeys.createdAt.rawValue,
        descending: Bool = true,
        limit: Int = 20,
        lastDocument: DocumentSnapshot? = nil
    ) async throws -> ([T], DocumentSnapshot?) {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date.now)! // FIXME: Force unwrapping이 최선인가...?!
        let oneMonthAgoTimestamp = Timestamp(date: oneMonthAgo)
        
        var q: Query = db.collection(type.rawValue)
            .whereField(receiverIds, arrayContains: userId)
            .whereField(teamspaceField, isEqualTo: currentTeamspaceId)
            .whereField(orderKey, isGreaterThan: oneMonthAgoTimestamp)
            .order(by: orderKey, descending: descending)
            .limit(to: limit)
        
        if let lastDoc = lastDocument { q = q.start(afterDocument: lastDoc) }
        
        let snap = try await q.getDocuments()
        let notificationList = snap.documents.compactMap { doc -> T? in try? doc.data(as: T.self) }
        let lastSnap = snap.documents.last
        
        return (notificationList, lastSnap)
    }
    
    
    func delete(collectionType: CollectionType, documentID: String) async throws {
        try await db
            .collection(collectionType.rawValue)
            .document(documentID)
            .delete()
    }
    
    
    /// 특정 컬렉션에서 지정된 필드값이 일치하는 모든 문서를 삭제합니다.
    /// - Parameters:
    ///   - collectionType: 삭제할 컬렉션
    ///   - fieldName: 비교할 필드 이름 (예: "teamspaceId", "projectId" 등)
    ///   - value: 필드 값
    /// - Throws: Firestore 작업 중 발생한 오류
    func deleteAllDocuments(
        from collectionType: CollectionType,
        whereField fieldName: String,
        isEqualTo value: String
    ) async throws {
        let querySnapshot = try await db
            .collection(collectionType.rawValue)
            .whereField(fieldName, isEqualTo: value)
            .getDocuments()
        
        print("삭제 대상 문서 수: \(querySnapshot.documents.count)개 (\(collectionType.rawValue))")
        
        // 안정성을 위해 순차적으로 처리
        for document in querySnapshot.documents {
            try await document.reference.delete()
            print("삭제 완료: \(document.documentID)")
        }
        
        print("\(collectionType.rawValue) 컬렉션에서 '\(fieldName)' == '\(value)' 문서 삭제 완료")
    }
    
    /// 특정 부모 문서 하위의 서브컬렉션의 특정 문서를 제거합니다.
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
    
    
    /// 특정 부모 문서 하위의 서브컬렉션의 모든 데이터를 제거합니다.
    /// - Parameters:
    ///   - parentType: 부모 컬렉션(.user 등)
    ///   - parentId: 부모 문서 ID(userId 등)
    ///   - subType: 서브컬렉션(.blocks 등)
    ///   - pageSize: 문서 삭제 갯수 (default == 300)
    @discardableResult
    func deleteAllDocumentsInSubcollection(
        under parentType: CollectionType,
        parentId: String,
        subCollection subType: CollectionType,
        pageSize: Int = 300 // 삭제 데이터 제한을 300개로 설정
    ) async throws -> Int {

        let subRef = db
            .collection(parentType.rawValue)
            .document(parentId)
            .collection(subType.rawValue)

        var totalDeleted = 0

        while true {
            let snap = try await subRef.limit(to: pageSize).getDocuments()
            guard snap.isEmpty == false else { break }

            let batch = db.batch()
            snap.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
            totalDeleted += snap.count
        }

        return totalDeleted
    }

  
    func deleteFromSubSubcollection(
        in grandParentType: CollectionType,
        grandParentId: String,
        withIn parentType: CollectionType,
        parentId: String,
        subCollection subType: CollectionType,
        target documentID: String
    ) async throws {
        try await db
            .collection(grandParentType.rawValue)
            .document(grandParentId)
            .collection(parentType.rawValue)
            .document(parentId)
            .collection(subType.rawValue)
            .document(documentID)
            .delete()
    }
}

