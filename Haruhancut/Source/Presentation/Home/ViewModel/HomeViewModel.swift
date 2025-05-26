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
    var cameraType: CameraType { get }
    
    func transform() -> HomeViewModel.Output
    func addComment(post: Post, text: String)
    func deleteComment(post: Post, commentId: String)
    func uploadPost(image: UIImage) -> Observable<Bool>
    func stopObservingGroup()
    func uploadProfileImage(_ image: UIImage) -> Observable<URL?>
}


final class HomeViewModel: HomeViewModelType {
    
    private let disposeBag = DisposeBag()
    private let loginUsecase: LoginUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol
    let user = BehaviorRelay<User?>(value: nil)
    let group = BehaviorRelay<HCGroup?>(value: nil)
    let posts = BehaviorRelay<[Post]>(value: [])
    var cameraType: CameraType
    
    // 스냅샷 구독
    private var groupSnapshotDisposable: Disposable?

    var didUserPostToday: Observable<Bool> {
        return Observable.combineLatest(user, posts)
            .map { user ,posts in
                guard let uid = user?.uid else { return false }
                return posts.contains { $0.isToday && $0.userId == uid }
        }
    }
    
    struct Output {
        let posts: Driver<[Post]>
        let groupName: Driver<String>
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
        
        user
            .compactMap { $0?.groupId }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] groupId in
                guard let self = self else { return }
                self.observeGroupRealtime(groupId: groupId)
            })
            .disposed(by: disposeBag)
        
        /*
        MARK: - 이 방식을 사용하면 초기 실행 시점에만 groulId가 있을 경우만 작동한다. userRelay는 로그인 직후 비동기적으로 값이 들어오므로 init 시점에는 nil 가능성이 크다. 즉 groulId가 나중에 들어와도 반응을 하지 못한다
        /// 서버에서 그룹 불러오기
        if let groupId = user.value?.groupId {
            // fetchGroup(groupId: groupId)
            observeGroupRealtime(groupId: groupId)
        } else {
            print("그룹이 없음")
        }
         */
 
        
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
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { success in
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
        
        groupSnapshotDisposable?.dispose() // ✅ 기존 스냅샷 제거

        groupSnapshotDisposable = FirebaseAuthManager.shared.observeValueStream(path: path, type: HCGroupDTO.self)
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
        print("🛑 그룹 실시간 스냅샷 종료됨")
    }
}

final class StubHomeViewModel: HomeViewModelType {
    var cameraType: CameraType
    let posts: BehaviorRelay<[Post]>
    let user: BehaviorRelay<User?>
    let group: BehaviorRelay<HCGroup?>

    init(previewPost: Post, cameraType: CameraType = .camera) {
        self.posts = BehaviorRelay(value: [previewPost])
        self.user = BehaviorRelay(value: User.empty(loginPlatform: .kakao))
        self.group = BehaviorRelay(value: nil)
        self.cameraType = cameraType
    }

    func transform() -> HomeViewModel.Output {
        return HomeViewModel.Output(
            posts: posts.asDriver(onErrorJustReturn: []),
            groupName: group.map { $0?.groupName ?? "그룹 없음" }.asDriver(onErrorJustReturn: "그룹 없음")
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
        ()
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
}


