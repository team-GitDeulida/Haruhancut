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
    private let post: Post
    
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
        return iv
    }()
    
    private lazy var commentButton: HCCommentButton = {
        let button = HCCommentButton(image: UIImage(systemName: "message")!, count: post.comments.count)
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
        commentButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let commentVC = PostCommentViewController(homeViewModel: self.homeViewModel, post: post)
                commentVC.modalPresentationStyle = .pageSheet
                self.present(commentVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
}



//#Preview {
//    PostDetailViewController(homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao))), post: .samplePosts[0])
//}


#Preview {
    let stub = HomeViewModel(
        loginUsecase: StubLoginUsecase(),
        groupUsecase: StubGroupUsecase(),
        userRelay: .init(value: User.empty(loginPlatform: .kakao))
    )
    stub.posts.accept(Post.samplePosts) // ✅ 댓글 포함된 샘플 데이터 주입
    return PostDetailViewController(homeViewModel: stub, post: Post.samplePosts[0])
}
