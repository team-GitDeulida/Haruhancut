//
//  HomeViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/18/25.
//

import UIKit
import RxSwift
import RxCocoa

enum CameraType {
    case camera
    case gallary
}

protocol HomeViewModelType {
    var posts: BehaviorRelay<[Post]> { get }
    var user: BehaviorRelay<User?> { get }
    var group: BehaviorRelay<HCGroup?> { get }
    var members: BehaviorRelay<[User]> { get }
    var cameraType: CameraType { get }
    var didUserPostToday: Observable<Bool> { get }
    
    func transform() -> HomeViewModel.Output
    func addComment(post: Post, text: String)
    func deleteComment(post: Post, commentId: String)
    func uploadPost(image: UIImage) -> Observable<Bool>
    func stopObservingGroup()
    func uploadProfileImage(_ image: UIImage) -> Observable<URL?>
    func fetchGroup(groupId: String)
    func deletePost(_ post: Post)
}


final class HomeViewModel: HomeViewModelType {
    
    private let disposeBag = DisposeBag()
    private let loginUsecase: LoginUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol
    let user = BehaviorRelay<User?>(value: nil)
    let group = BehaviorRelay<HCGroup?>(value: nil)
    let posts = BehaviorRelay<[Post]>(value: [])
    var cameraType: CameraType
    let members = BehaviorRelay<[User]>(value: [])
    
    // 스냅샷 구독
    private var groupSnapshotDisposable: Disposable?
    private var userSnapshotDisposable: Disposable?
    private var memberSnapshotDisposables: [String: Disposable] = [:]

    var didUserPostToday: Observable<Bool> {
        return Observable.combineLatest(user, posts)
            .map { user ,posts in
                guard let uid = user?.uid else { return false }
                return posts.contains { $0.isToday && $0.userId == uid }
        }
    }
    
    struct Output {
        let todayPosts: Driver<[Post]>
        let groupName: Driver<String>
        let allPostsByDate: Driver<[String: [Post]]>
    }
    
    init(loginUsecase: LoginUsecaseProtocol, groupUsecase: GroupUsecaseProtocol, userRelay: BehaviorRelay<User?>, cameraType: CameraType = .camera) {
        self.loginUsecase = loginUsecase
        self.groupUsecase = groupUsecase
        self.cameraType = cameraType
        
        // MARK: - 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopObservingGroup),
            name: .userForceLoggedOut,
            object: nil
        )

        
        /// homeVM이 유저 상태를 실시간 반영받도록 userRelay를 직접 참조
        /// userRelay에 변화가 생기면, HomeViewModel.user에게 그 값을 자동으로 전달
        userRelay
            .bind(to: user)
            .disposed(by: disposeBag)
        
        /// 캐시 그룹 불러오기
        fetchDefaultGroup()
        
        // 그룹 스냅샷
        user
            .compactMap { $0?.groupId }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] groupId in
                guard let self = self else { return }
                self.observeGroupRealtime(groupId: groupId)
            })
            .disposed(by: disposeBag)
        
        // 유저 스냅샷
        /*
        user
            .compactMap { $0?.uid }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] uid in
                guard let self = self else { return }
                self.observeUserRealtime(uid: uid)
            })
            .disposed(by: disposeBag)
         */
        
        // 멤버 스냅샷
        group
            .compactMap { $0?.members.map { $0.key } }
            .distinctUntilChanged { $0 == $1 }
            .subscribe(onNext: { [weak self] memberUIDs in
                self?.observeAllMembersRealtime(memberUIDs: memberUIDs)
            })
            .disposed(by: disposeBag)
    }
    
    func transform() -> Output {
        
        // 1) 오늘 것만
        let todayPosts = posts
            .map { $0.filter { $0.isToday } }
            .asDriver(onErrorJustReturn: [])
        
        // 2) 그룹 이름
        let groupName = group
            .map { $0?.groupName ?? "그룹 없음" }
            .asDriver(onErrorJustReturn: "그룹 없음")
        
        // 3) 전체 포스트 맵(날짜 → [Post])
        let allPostsByDate = group
            .map { $0?.postsByDate ?? [:] }
            .asDriver(onErrorJustReturn: [:])
        
        return Output(todayPosts: todayPosts, groupName: groupName, allPostsByDate: allPostsByDate)
    }
    
    /// 포스트 추가 함수
    func uploadPost(image: UIImage) -> Observable<Bool> {
        
        if cameraType == .camera {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        
        guard let user = user.value,
              let groupId = group.value?.groupId else {
            print("❌ 유저 또는 그룹 정보 없음")
            return .just(false)
        }

        let postId = UUID().uuidString
        let dateKey = Date().toDateKey()
        let storagePath = "groups/\(groupId)/images/\(postId).jpg"
        let dbPath = "groups/\(groupId)/postsByDate/\(dateKey)/\(postId)"

        return FirebaseStorageManager.shared.uploadImage(image: image, path: storagePath)
            .flatMap { url -> Observable<Bool> in
                guard let imageURL = url else {
                    print("❌ URL 없음")
                    return .just(false)
                }

                let post = Post(
                    postId: postId,
                    userId: user.uid,
                    nickname: user.nickname,
                    profileImageURL: user.profileImageURL,
                    imageURL: imageURL.absoluteString,
                    createdAt: Date(), likeCount: 0,
                    comments: [:]
                )

                return FirebaseAuthManager.shared.setValue(path: dbPath, value: post.toDTO())
            }
    }
    
    // 포스트 삭제 함수
    func deletePost(_ post: Post) {
        guard let groupId = group.value?.groupId else { return }

        let dateKey = post.createdAt.toDateKey()
        let dbPath = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)"
        let storagePath = "groups/\(groupId)/images/\(post.postId).jpg"
        
        // 1. DB에서 삭제
        FirebaseAuthManager.shared.deleteValue(path: dbPath)
            .flatMap { success -> Observable<Bool> in
                guard success else { return .just(false) }
                
                
                // 2. Storage에서도 삭제
                return FirebaseStorageManager.shared.deleteImage(path: storagePath)
            }
            .bind(onNext: { success in
                if success {
                    print("✅ 삭제 완료")
                } else {
                    print("❌ 삭제 실패")
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// 댓글 추가 함수
    /// - Parameters:
    ///   - post: 댓글을 작성할 게시물
    ///   - text: 댓글 텍스트
    func addComment(post: Post, text: String) {
        // 유저 정보 없으면 리턴
        guard let user = user.value else { return }
        guard let groupId = group.value?.groupId else { return }
        
        let commentId = UUID().uuidString
        let newComment = Comment(
            commentId: commentId,
            userId: user.uid,
            nickname: user.nickname,
            profileImageURL: user.profileImageURL,
            text: text,
            createdAt: Date()
        )
        
        // 경로: groups/{groupId}/postsByDate/{날짜}/{postId}/comments/{commentId}
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        let commentDTO = newComment.toDTO()

        FirebaseAuthManager.shared.setValue(path: path, value: commentDTO)
            .subscribe(onNext: { success in
                if success {
                    print("✅ 댓글 저장 성공")
                    // ❌ posts.accept(newPosts) 는 하지 않음
                    // 🔁 실시간 스냅샷이 알아서 posts를 갱신함
                } else {
                    print("❌ 댓글 저장 실패")
                }
            })
            .disposed(by: disposeBag)
    }

    /// 댓글 삭제 함수
    /// - Parameters:
    ///   - post: 댓글이 포함된 게시물
    ///   - commentId: 삭제할 댓글 Id
    func deleteComment(post: Post, commentId: String) {
        guard let groupId = group.value?.groupId else { return }
        
        // 게시글 작성된 날짜를 키로 변환 (예: "2025-05-20")
        let dateKey = post.createdAt.toDateKey()
        
        // 삭제할 댓글의 경로 구성
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        
        FirebaseAuthManager.shared.deleteValue(path: path)
            .subscribe(onNext: { success in
                if success {
                    print("✅ 댓글 삭제 성공")

                } else {
                    print("❌ 댓글 삭제 실패")
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchDefaultGroup() {
        if let cachedGroup = UserDefaultsManager.shared.loadGroup() {
            // print("✅ homeVM - 캐시에서 불러온 그룹: \(cachedGroup)")
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
    func fetchGroup(groupId: String) {
        groupUsecase.fetchGroup(groupId: groupId)
            .bind(onNext: { result in
                switch result {
                case .success(let group):
                    // print("✅ homeVM - 서버에서 불러온 그룹: \(group)")
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
    
    // MARK: - 그룹의 사진, 댓글 실시간 변경을 위한 스냅샷
    /// 서버의 데이터를 실시간으로 관찰
    /// - Parameter groupId: 그룹 Id
    private func observeGroupRealtime(groupId: String) {
        let path = "groups/\(groupId)"
        
        groupSnapshotDisposable?.dispose() // ✅ 기존 스냅샷 제거

        groupSnapshotDisposable = FirebaseAuthManager.shared.observeValueStream(path: path, type: HCGroupDTO.self)
            .compactMap { $0.toModel() }
            .subscribe(onNext: { [weak self] group in
                guard let self = self else { return }
                // print("🔥 observeGroupRealtime 변경 감지됨: \(group)")
                self.group.accept(group)
                
                // 캐시 저장
                UserDefaultsManager.shared.saveGroup(group)
                let allPosts = group.postsByDate
                    .flatMap { $0.value }
                    .sorted(by: { $0.createdAt < $1.createdAt }) // 오래된 순
                self.posts.accept(allPosts)
            }, onError: { error in
                print("❌ 사용자 정보 없음 캐시 삭제 진행")
                self.user.accept(nil)
                UserDefaultsManager.shared.removeUser()
                UserDefaultsManager.shared.removeGroup()
                
                // 강제 로그아웃 유도
                NotificationCenter.default.post(name: .userForceLoggedOut, object: nil)
            }
        )
    }
    
    // MARK: - 프로필 실시간 변경을 위한 스냅샷
    private func observeUserRealtime(uid: String) {
        let path = "users/\(uid)"
        
        // 기존 구독 중단
        userSnapshotDisposable?.dispose()
        
        userSnapshotDisposable = FirebaseAuthManager.shared.observeValueStream(path: path, type: UserDTO.self)
            .compactMap { $0.toModel() }
            .subscribe(
                onNext: { [weak self] user in
                guard let self = self else { return }
                self.user.accept(user)
                // print("🔥 observeUserRealtime 변경 감지됨: \(user)")
                print("🔥 유저 변경 감지")
            },
                onError: { error in
                    print("❌ 사용자 정보 없음 캐시 삭제 진행")
                    self.user.accept(nil)
                    UserDefaultsManager.shared.removeUser()
                    UserDefaultsManager.shared.removeGroup()
                    
                    // 강제 로그아웃 유도
                    NotificationCenter.default.post(name: .userForceLoggedOut, object: nil)
                }
            )
    }
    
    // MARK: - Members 각 uid마다 observeStream으로 실시간 구독
//    private func observeMembersRealtime(memberUIDs: [String]) {
//        // 기존에 없는 UID는 구독 추가
//        memberUIDs.forEach { uid in
//            observeUserRealtime(uid: uid)
//        }
//        
//        // 빠진 UID는 구독 해제 및 배열에서 제거
//        let removedUIDs = Set(memberSnapshotDisposables.keys).subtracting(memberUIDs)
//        removedUIDs.forEach { uid in
//            memberSnapshotDisposables[uid]?.dispose()
//            memberSnapshotDisposables.removeValue(forKey: uid)
//        }
//    }
    
    func observeAllMembersRealtime(memberUIDs: [String]) {
        // 1. 신규 uid 구독 추가
        memberUIDs.forEach { uid in
            if memberSnapshotDisposables[uid] == nil {
                let disposable = FirebaseAuthManager.shared.observeValueStream(path: "users/\(uid)", type: UserDTO.self)
                    .compactMap { $0.toModel() }
                    .subscribe(
                        onNext: { [weak self] user in
                        guard let self = self else { return }
                        var current = self.members.value
                        if let idx = current.firstIndex(where: { $0.uid == user.uid }) {
                            current[idx] = user
                        } else {
                            current.append(user)
                        }
                        self.members.accept(current)
                        print("🔥 members 업데이트 \(user.nickname)")
                    },
                        onError: { error in
                            print("❌ 사용자 정보 없음 캐시 삭제 진행")
                            self.user.accept(nil)
                            UserDefaultsManager.shared.removeUser()
                            UserDefaultsManager.shared.removeGroup()
                            
                            // 강제 로그아웃 유도
                            NotificationCenter.default.post(name: .userForceLoggedOut, object: nil)
                        }
                    )
                memberSnapshotDisposables[uid] = disposable
            }
        }
        // 2. 더 이상 없는 uid 구독 해제 및 members에서 제거
        let removedUIDs = Set(memberSnapshotDisposables.keys).subtracting(memberUIDs)
        removedUIDs.forEach { uid in
            memberSnapshotDisposables[uid]?.dispose()
            memberSnapshotDisposables.removeValue(forKey: uid)
            var current = self.members.value
            current.removeAll { $0.uid == uid }
            self.members.accept(current)
        }
    }

    
    
    
    
    func uploadProfileImage(_ image: UIImage) -> Observable<URL?> {
        guard let user = user.value else {
            return .just(nil)
        }

        let path = "users/\(user.uid)/profile.jpg"

        return FirebaseStorageManager.shared.uploadImage(image: image, path: path)
    }

    
    /// 스냅샷 종료
    @objc func stopObservingGroup() {
        groupSnapshotDisposable?.dispose()
        groupSnapshotDisposable = nil
        
        userSnapshotDisposable?.dispose()
        userSnapshotDisposable = nil
        
        // 멤버 스냅샷 모두 종료
        memberSnapshotDisposables.values.forEach { $0.dispose() }
        memberSnapshotDisposables.removeAll()
        
        print("🛑 그룹/유저 실시간 스냅샷 종료됨")
    }
}

final class StubHomeViewModel: HomeViewModelType {
    
    var cameraType: CameraType
    let posts: BehaviorRelay<[Post]>
    let user: BehaviorRelay<User?>
    let group: BehaviorRelay<HCGroup?>
    let members = BehaviorRelay<[User]>(value: [])
    var didUserPostToday: Observable<Bool>

    init(previewPost: Post, cameraType: CameraType = .camera) {
        self.posts = BehaviorRelay(value: [previewPost])
        self.user = BehaviorRelay(value: User.empty(loginPlatform: .kakao))
        self.group = BehaviorRelay(value: HCGroup.sampleGroup)
        self.cameraType = cameraType
        self.didUserPostToday = .just(false)
    }

    func transform() -> HomeViewModel.Output {
        return HomeViewModel.Output(
            todayPosts: posts.asDriver(onErrorJustReturn: []),
            groupName: group.map { $0?.groupName ?? "그룹 없음" }.asDriver(onErrorJustReturn: "그룹 없음"), allPostsByDate: .just([:])
        )
    }
    
    func addComment(post: Post, text: String) {
        // 유저 정보 없으면 아무것도 안하고 리턴
        guard let user = user.value else { return }
        
        // 현재 posts 배열 복사
        var newPosts = posts.value
        
        // 댓글을 달 대상 post의 인덱스 찾기
        guard let index = newPosts.firstIndex(where: { $0.postId == post.postId }) else { return }
        
        // 새로운 댓글 생성
        let commentId = UUID().uuidString
        let newComment = Comment(
            commentId: commentId,
            userId: user.uid,
            nickname: user.nickname,
            profileImageURL: user.profileImageURL,
            text: text,
            createdAt: Date()
        )
        
        // 게시물에 댓글 추가
        newPosts[index].comments[commentId] = newComment
        
        posts.accept(newPosts)
    }
    
    func deleteComment(post: Post, commentId: String) {
    }
    
    func uploadPost(image: UIImage) -> Observable<Bool> {
        return .just(false)
    }
    
    func stopObservingGroup() {
        print("스냅샷 종료")
    }
    
    func uploadProfileImage(_ image: UIImage) -> Observable<URL?> {
        guard let user = user.value else {
            return .just(nil)
        }

        let path = "users/\(user.uid)/profile.jpg"

        return FirebaseStorageManager.shared.uploadImage(image: image, path: path)
    }
    
    func fetchGroup(groupId: String) {
        
    }
    
    func deletePost(_ post: Post) {}
}


