//
//  HomeViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/18/25.
//

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel {
    
    private let disposeBag = DisposeBag()
    private let loginUsecase: LoginUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol
    let user = BehaviorRelay<User?>(value: nil)
    let group = BehaviorRelay<HCGroup?>(value: nil)
    let posts = BehaviorRelay<[Post]>(value: [])
    
    struct Output {
        let posts: Driver<[Post]>
    }
    
    init(loginUsecase: LoginUsecaseProtocol, groupUsecase: GroupUsecaseProtocol, userRelay: BehaviorRelay<User?>) {
        self.loginUsecase = loginUsecase
        self.groupUsecase = groupUsecase
        
        /// homeVM이 유저 상태를 실시간 반영받도록 userRelay를 직접 참조
        /// userRelay에 변화가 생기면, HomeViewModel.user에게 그 값을 자동으로 전달
        userRelay
            .bind(to: user)
            .disposed(by: disposeBag)
        
        /// 캐시 그룹 불러오기
        fetchDefaultGroup()
        
        /// 서버에서 그룹 불러오기
        if let groupId = user.value?.groupId {
            fetchGroup(groupId: groupId)
        }
        
        /// 임시 하드코딩
        posts.accept(Post.samplePost1 + Post.samplePost2 + Post.samplePost3)
    }
    
    func transform() -> Output {
        return Output(posts: posts.asDriver())
    }
    
    func fetchDefaultGroup() {
        if let cachedGroup = UserDefaultsManager.shared.loadGroup() {
            print("✅ homeVM - 캐시에서 불러온 그룹: \(cachedGroup)")
            self.group.accept(cachedGroup)
        } else {
            print("❌ 캐시된 그룹 없음 --- ")
        }
    }

    /// 서버에서 그룹 정보 불러오기
    /// - Parameter groupId: 그룹Id
    private func fetchGroup(groupId: String) {
        groupUsecase.fetchGroup(groupId: groupId)
            .bind(onNext: { result in
                switch result {
                case .success(let group):
                    print("✅ homeVM - 서버에서 불러온 그룹: \(group)")
                    self.group.accept(group)
                    UserDefaultsManager.shared.saveGroup(group)
                    
                case .failure(let error):
                    print("❌ 그룹 가져오기 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }
}

/*
/// 캐시 정보 불러오기
private func loadCachedUserAndGroup() {
    if let cachedUser = UserDefaultsManager.shared.loadUser() {
        print("✅ homeVM - loadCachedUserAndGroup() 캐시된 유저 불러오기 성공: \(cachedUser)")
        self.user.accept(cachedUser)
    } else {
        print("❌ 캐시된 유저 없음 --- ")
    }
    
    if let cachedGroup = UserDefaultsManager.shared.loadGroup() {
        print("✅ homeVM - loadCachedUserAndGroup() 캐시된 그룹 불러오기 성공: \(cachedGroup)")
        self.group.accept(cachedGroup)
    } else {
        print("❌ 캐시된 그룹 없음 --- ")
    }
}
 */

/*
/// 서버에서 유저 정보 불러오기
private func fetchUserInfo() {
    loginUsecase.fetchUserInfo()
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { [weak self] user in
            guard let self = self, let user = user else {
                print("❌ 유저 가져오기 실패")
                return
            }
            print("✅ homeVM - fetchUserInfo(): \(user)")
            self.user.accept(user)
            
            if let groupId = user.groupId {
                self.fetchGroup(groupId: groupId)
            }
        })
        .disposed(by: disposeBag)
}
 */

/*
 func bindButtonTap(tap: Observable<Void>) {
     tap.subscribe(onNext: {
         print("hello world")
     })
     .disposed(by: disposeBag)
 }
 */
