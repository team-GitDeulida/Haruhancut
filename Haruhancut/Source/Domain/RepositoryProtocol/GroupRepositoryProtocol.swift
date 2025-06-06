//
//  GroupRepositoryProtocol.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import Foundation
import RxSwift

protocol GroupRepositoryProtocol {
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
}
