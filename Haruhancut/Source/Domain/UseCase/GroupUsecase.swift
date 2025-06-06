//
//  GroupUsecase.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import Foundation
import RxSwift

protocol GroupUsecaseProtocol {
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
}

final class GroupUsecase: GroupUsecaseProtocol {
    
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    /// 그룹 Creaate
    /// - Parameter groupName: 그룹 이름
    /// - Returns: Observable<Result<그룹Id, GroupError>>
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        repository.createGroup(groupName: groupName)
    }
    
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>> {
        repository.updateUserGroupId(groupId: groupId)
    }
    
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
        repository.fetchGroup(groupId: groupId)
    }
    
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
        repository.joinGroup(inviteCode: inviteCode)
    }
}

final class StubGroupUsecase: GroupUsecaseProtocol {
    
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        return .just(.success(("testGroupId", "1234")))
    }
    
    func updateUserGroupId(groupId: String) -> RxSwift.Observable<Result<Void, GroupError>> {
        return .just(.success(()))
    }
    
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
        return .just(.failure(.fetchGroupError))
    }
    
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
        return .just(.success(HCGroup.sampleGroup))
    }
}
