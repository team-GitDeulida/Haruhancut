//
//  MemberViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 5/28/25.
//

import RxSwift
import RxCocoa

protocol MemberViewModelType {
    var membersRelay: BehaviorRelay<[User]> { get }
    var members: Driver<[User]> { get }
    
//    var groupRelay: BehaviorRelay<HCGroup> { get }
//    var group: Driver<HCGroup> { get }
}

final class MemberViewModel: MemberViewModelType {
    private let loginUsecase: LoginUsecaseProtocol
    private let disposeBag = DisposeBag()
    
    // 멤버 관련
    var membersRelay: BehaviorRelay<[User]>
    var members: Driver<[User]> { membersRelay.asDriver() }
    
    // 그룹 관련
    // var groupRelay: BehaviorRelay<HCGroup>
    // var group: Driver<HCGroup> { groupRelay.asDriver() }
    
    init(loginUsecase: LoginUsecaseProtocol,
         membersRelay: BehaviorRelay<[User]>
         // ,groupRelay: BehaviorRelay<HCGroup>
    ) {
        self.loginUsecase = loginUsecase
        self.membersRelay = membersRelay
        // self.groupRelay = groupRelay
        
        // print("그룹 정보: \(groupRelay.value)")
    }
}

final class StubMemberViewModel: MemberViewModelType {
//    var groupRelay = BehaviorRelay<HCGroup>(value: .emptyGroup)
//    var group: Driver<HCGroup> { groupRelay.asDriver() }
    
    var membersRelay = BehaviorRelay<[User]>(value: [User.empty(loginPlatform: .kakao), User.empty(loginPlatform: .kakao), User.empty(loginPlatform: .kakao)])
    var members: Driver<[User]> { membersRelay.asDriver() }
}






