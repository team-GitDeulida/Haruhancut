//
//  MemberViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 5/28/25.
//

import RxSwift
import RxCocoa

protocol MemberViewModelType {
    var group: Driver<HCGroup> { get }
    var members: Driver<[User]> { get }
    func fetchMembers()
    func fetchUser(uid: String) -> Observable<User?>
}

final class MemberViewModel: MemberViewModelType {
    private let loginUsecase: LoginUsecaseProtocol
    
    let groupRelay: BehaviorRelay<HCGroup>
    var group: Driver<HCGroup> { groupRelay.asDriver() }
    
    let membersRelay = BehaviorRelay<[User]>(value: [])
    var members: Driver<[User]> { membersRelay.asDriver() }
    private let disposeBag = DisposeBag()
    
    init(loginUsecase: LoginUsecaseProtocol, groupRelay: BehaviorRelay<HCGroup>) {
        self.loginUsecase = loginUsecase
        self.groupRelay = groupRelay
        self.fetchMembers()
    }
    
    func fetchMembers() {
        // groupRelay 변경시마다 멤버 uid를 모두 fetch해서 memberRelay로 뿌려준다
        groupRelay
            .asObservable()
            .flatMapLatest { [weak self] group -> Observable<[User]> in
                guard let self = self else { return .just([])}
                let userFetchObservables = group.members.keys.map { self.fetchUser(uid: $0) }
                return Observable.zip(userFetchObservables).map { $0.compactMap { $0 } }
            }
            .bind(to: membersRelay)
            .disposed(by: disposeBag)
    }
    
    func fetchUser(uid: String) -> Observable<User?> {
        loginUsecase.fetchUser(uid: uid)
    }
}

final class StubMemberViewModel: MemberViewModelType {
    
    let groupRelay: BehaviorRelay<HCGroup>
    var group: Driver<HCGroup> { groupRelay.asDriver() }
    
    var membersRelay = BehaviorRelay<[User]>(value: [])
    var members: Driver<[User]> { membersRelay.asDriver() }
    
    init(groupRelay: BehaviorRelay<HCGroup>, membersRelay: BehaviorRelay<[User]>) {
        self.groupRelay = groupRelay
        self.membersRelay = membersRelay
    }
    
    func fetchMembers() {}
    
    func fetchUser(uid: String) -> Observable<User?> {
        return .just(.empty(loginPlatform: .kakao))
    }
}

