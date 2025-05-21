//
//  GroupRepository.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import Foundation
import RxSwift

final class GroupRepository: GroupRepositoryProtocol {
    
    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    
    init(firebaseAuthManager: FirebaseAuthManagerProtocol) {
        self.firebaseAuthManager = firebaseAuthManager
    }
    
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        firebaseAuthManager.createGroup(groupName: groupName)
    }
    
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>> {
        firebaseAuthManager.updateUserGroupId(groupId: groupId)
    }
    
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
        firebaseAuthManager.fetchGroup(groupId: groupId)
    }
    
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        firebaseAuthManager.joinGroup(inviteCode: inviteCode)
    }
}
