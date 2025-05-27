//
//  PostDetailViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/17/25.
//

import UIKit
import RxSwift


final class PostDetailViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?
    private var post: Post
    
    private let homeViewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    
    init(homeViewModel: HomeViewModel, post: Post) {
        self.post = post
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
        self.configure(with: post)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with post: Post) {
        let url = URL(string: post.imageURL)
        imageView.kf.setImage(with: url)
    }
    
    // MARK: - UI Component
    // 이미지 뷰: 셀의 배경 이미지를 보여줌
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill           // 셀 채우되 비율 유지
        iv.clipsToBounds = true                     // 셀 밖 이미지 자르기
        iv.layer.cornerRadius = 15                  // 모서리 둥글게
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = true          // 터치 감지 가능하도록 설정
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        iv.addGestureRecognizer(tapGesture)
        return iv
    }()
    
    private lazy var commentButton: HCCommentButton = {
        let button = HCCommentButton(image: UIImage(systemName: "message")!, count: 0)
        return button
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        setupConstraints()
        bindViewModel()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        [imageView, commentButton].forEach {
            view.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 위치
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            // 크기
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
        
        NSLayoutConstraint.activate([
            // 위치
            commentButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            commentButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])
    }
    
    // MARK: - Bind
    private func bindViewModel() {
        // 버튼을 누르면 네비게이션 present 화면을 띄운다
        commentButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let commentVC = PostCommentViewController(homeViewModel: self.homeViewModel, post: post)
                commentVC.modalPresentationStyle = .pageSheet
                self.present(commentVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 게시물 업데이트 감지 후 댓글 수 반영 및 이미지 갱신
        homeViewModel.posts
            // 1. viewModel의 posts중 post와 동일한 postId를 가진 게시물 찾기
            .compactMap { posts in
                posts.first(where: { $0.postId == self.post.postId })
            }
            // 2. 댓글 수 변경시만 downstream으로 이벤트 방출
            .distinctUntilChanged({ $0.comments.count == $1.comments.count })
            // 3. UI 업데이트이므로 Driver로 변환(메인스레드 보장)
            .asDriver(onErrorDriveWith: .empty())
            // 4. 최신 post로 갱신 및 UI 업데이트
            .drive(onNext: { [weak self] updatedPost in
                self?.post = updatedPost
                self?.configure(with: updatedPost)
                self?.commentButton.setCount(updatedPost.comments.count)
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func didTapImage() {
        let previewVC = ImagePreviewViewController(image: imageView.image!)
        previewVC.modalPresentationStyle = .fullScreen
        self.present(previewVC, animated: true)
    }
}

#Preview {
    let stub = HomeViewModel(
        loginUsecase: StubLoginUsecase(),
        groupUsecase: StubGroupUsecase(),
        userRelay: .init(value: User.empty(loginPlatform: .kakao))
    )
    stub.posts.accept(Post.samplePosts) // ✅ 댓글 포함된 샘플 데이터 주입
    return PostDetailViewController(homeViewModel: stub, post: Post.samplePosts[0])
}
