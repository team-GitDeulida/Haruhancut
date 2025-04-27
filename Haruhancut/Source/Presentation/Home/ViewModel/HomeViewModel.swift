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
    
    init(loginUsecase: LoginUsecaseProtocol, groupUsecase: GroupUsecaseProtocol) {
        self.loginUsecase = loginUsecase
        self.groupUsecase = groupUsecase
        loadCachedUserAndGroup()
        fetchUserInfo()
    }
    
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
    
    func bindButtonTap(tap: Observable<Void>) {
        tap.subscribe(onNext: {
            print("hello world")
        })
        .disposed(by: disposeBag)
    }
    
    private func fetchGroup(groupId: String) {
        groupUsecase.fetchGroup(groupId: groupId)
            .bind(onNext: { result in
                switch result {
                case .success(let group):
                    print("✅ homeVM - fetchGroup(): \(group)")
                    self.group.accept(group)
                    UserDefaultsManager.shared.saveGroup(group)
                    
                case .failure(let error):
                    print("❌ 그룹 가져오기 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }
}
