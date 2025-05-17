//
//  HomeViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

/*
 reference
 - https://dmtopolog.com/navigation-bar-customization/ (navigation bar)
 - https://dongdida.tistory.com/170 (CollectionView)
 
 ContentMode    설명
 .scaleAspectFit    이미지 비율 유지하면서 버튼 안에 "모두" 들어오게
 .scaleAspectFill    이미지가 버튼을 "가득" 채우게 (비율은 유지하지만 잘릴 수도 있음)
 .center    가운데 정렬만 하고 크기 안바꿈
 .top, .bottom, .left, .right    방향 맞춰서 위치만 변경
 
 */

import UIKit
import FirebaseAuth
import RxSwift
import RxCocoa

final class HomeViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Component
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "하루한컷"
        label.font = UIFont.hcFont(.bold, size: 20.scaled)
        label.textColor = .mainWhite
        return label
    }()
    
    private lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(startCamera), for: .touchUpInside)
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = layout.calculateItemSize(columns: 2)
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: PostCell.identifier)
        collectionView.backgroundColor = .background
        return collectionView
    }()
    
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 하루를 추가해보세요"
        label.font = UIFont.hcFont(.medium, size: 16.scaled)
        label.textColor = .mainWhite
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(loginViewModel: LoginViewModel, homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        setupConstraints()
        bindViewModel()
        print("✅ homeVC - \(homeViewModel.posts.value)")
    }
    
    // 비동기 데이터 받아오면 UI에 반영
    private func bindViewModel() {
        // 그룹 이름 바인딩
        homeViewModel.transform().groupName
            .drive(onNext: { [weak self] text in
                guard let self = self else { return }
                self.titleLabel.text = text
                self.titleLabel.sizeToFit()
            })
            .disposed(by: disposeBag)
        
        // 포스트 바인딩
        homeViewModel.transform().posts
            .drive(collectionView.rx.items(
                cellIdentifier: PostCell.identifier,
                cellType: PostCell.self)
            ) { _, post, cell in
                cell.configure(with: post)
            }
            .disposed(by: disposeBag)
        
        // 포스트가 비었을 때
        homeViewModel.transform().posts
            .drive(onNext: { [weak self] posts in
                guard let self = self else { return }
                self.emptyLabel.isHidden = !posts.isEmpty
            })
            .disposed(by: disposeBag)
        
        // 포스트 터치 바인딩(댓글창)
        collectionView.rx.modelSelected(Post.self)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { post in
                // let commentList = Array(post.comments.values) // Dictionary → Array
                // let detailVC = PostDetailViewController(comments: commentList)
                let detailVC = PostDetailViewController(homeViewModel: self.homeViewModel, post: post)
                detailVC.modalPresentationStyle = .pageSheet
                self.present(detailVC, animated: true)
                print("✅ 셀 선택됨: \(post.postId)")
            })
            .disposed(by: disposeBag)
        
        
    }
    
    private func makeUI() {
        setupLogoTitle()
        view.backgroundColor = .background

        /// setupUI
        [collectionView, cameraBtn, emptyLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: cameraBtn.topAnchor, constant: -20),
        ])
        
        NSLayoutConstraint.activate([
            // 위치
            cameraBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50.scaled),
            cameraBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
    }
    
    /// 로고 타이틀 설정
    private func setupLogoTitle() {
        /// 네비게이션 버튼 색상
        self.navigationController?.navigationBar.tintColor = .mainWhite
        
        /// 네비게이션 제목
        titleLabel.sizeToFit() // 글자 길이에 맞게 label 크기 조정
        self.navigationItem.titleView = titleLabel
        
        
        /// 네비게이션 버튼
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person"),
            style: .plain,
            target: self,
            action: #selector(startProfile)
        )
        
        /// 자식 화면에서 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "홈으로"
        navigationItem.backBarButtonItem = backItem
    }
    
    /// Rx처리가 오히려 오버 엔지니어링이라고 판단됨
    /// 프로필 화면 이동
    @objc private func startProfile() {
        coordinator?.startProfile()
    }
    
    /// 카메라 화면 이동
    @objc private func startCamera() {
        coordinator?.startCamera()
    }
}

extension UICollectionViewFlowLayout {
    /// 컬렉션 뷰 셀 크기를 자동으로 계산해주는 함수
    /// - Parameters:
    ///   - columns: 한 행에 보여줄 셀 개수
    ///   - spacing: 셀 사이 간격 (기본값 16)
    ///   - inset: 좌우 마진 (기본값 16)
    /// - Returns: 계산된 셀 크기
    func calculateItemSize(columns: Int, spacing: CGFloat = 16, inset: CGFloat = 16) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let totalSpacing = spacing * CGFloat(columns - 1) + inset * 2
        let itemWidth = (screenWidth - totalSpacing) / CGFloat(columns)
        return CGSize(width: itemWidth, height: itemWidth) // 정사각형 셀
    }
}

#Preview {
    HomeViewController(loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()), homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao))))
}


