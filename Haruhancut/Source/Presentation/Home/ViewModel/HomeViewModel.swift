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
        let groupName: Driver<String>
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
            // fetchGroup(groupId: groupId)
            observeGroupRealtime(groupId: groupId)
        }
 
        
        /// 임시 하드코딩
        // posts.accept(Post.samplePosts)
        // posts.accept(HCGroup.sampleGroup.postsByDate.flatMap { $0.value })
    }
    
    func transform() -> Output {
        
        let todayPosts = posts
            .map { $0.filter { $0.isToday } }
            .asDriver(onErrorJustReturn: [])
        
        let groupName = group
            .map { $0?.groupName ?? "그룹 없음" }
            .asDriver(onErrorJustReturn: "그룹 없음")
        
        return Output(posts: todayPosts, groupName: groupName)
    }
    
    func fetchDefaultGroup() {
        if let cachedGroup = UserDefaultsManager.shared.loadGroup() {
            print("✅ homeVM - 캐시에서 불러온 그룹: \(cachedGroup)")
            self.group.accept(cachedGroup)
            
            // posts 업데이트
            let allPosts = cachedGroup.postsByDate.flatMap { $0.value }
            let sortedPosts = allPosts.sorted(by: { $0.createdAt < $1.createdAt }) // 오래된 순
            self.posts.accept(sortedPosts)
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
                    
                    // posts 업데이트
                    let allPosts = group.postsByDate.flatMap { $0.value }
                    let sortedPosts = allPosts.sorted(by: { $0.createdAt < $1.createdAt }) // 오래된 순
                    self.posts.accept(sortedPosts)
                    
                case .failure(let error):
                    print("❌ 그룹 가져오기 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    /// 서버의 데이터를 실시간으로 관찰
    /// - Parameter groupId: 그룹 Id
    private func observeGroupRealtime(groupId: String) {
        let path = "groups/\(groupId)"

        FirebaseAuthManager.shared.observeValueStream(path: path, type: HCGroupDTO.self)
            .compactMap { $0.toModel() }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] group in
                guard let self = self else { return }
                print("🔥 observeGroupRealtime 변경 감지됨: \(group)")
                self.group.accept(group)
                
                // 캐시 저장
                UserDefaultsManager.shared.saveGroup(group)
                let todayPosts = group.postsByDate
                    .flatMap { $0.value }.filter { $0.isToday }
                    .filter { $0.isToday }
                    .sorted(by: { $0.createdAt < $1.createdAt }) // 오래된 순
                self.posts.accept(todayPosts)
            })
            .disposed(by: disposeBag)
    }

}

