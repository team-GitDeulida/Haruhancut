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
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = layout.calculateItemSize(columns: 2)
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumInteritemSpacing = 16      // 좌우 셀 간격
        layout.minimumLineSpacing = 16           // 위아래 셀 간격 = 정사각형 높이 + 30
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: PostCell.identifier)
        collectionView.backgroundColor = .background
        return collectionView
    }()
    
    private let bubbleView = BubbleView(text: "")
    
    private lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(startCamera), for: .touchUpInside)
        return button
    }()
    
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "당신의 하루가 가족의 따뜻한 기억이 됩니다.\n사진 한 장을 남겨주세요."
        label.font = UIFont.hcFont(.medium, size: 20.scaled)
        label.textColor = .mainWhite
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: - LoginVM 필요없으면 지우자
    init(loginViewModel: LoginViewModel, homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        setupConstraints()
        bindViewModel()
        setupLongPressGesture()
        // print("✅ homeVC - \(homeViewModel.posts.value)")
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
        
        // 포스트가 비었을 때 emptyLabel 보이게 동작
        homeViewModel.transform().posts
            .drive(onNext: { [weak self] posts in
                guard let self = self else { return }
                
                // 문구 보이게 하기
                self.emptyLabel.isHidden = !posts.isEmpty
                
                // 사진 추가하기 -> 오늘의 사진 추가 완료
                // 포스트가 비어있지 않으면서 내가 작성판 포스트가 하나라도 있다면
                if !posts.isEmpty && posts.contains(where: { $0.userId == self.homeViewModel.user.value?.uid }) {
                    self.bubbleView.text = "오늘 사진 추가 완료"
                    self.bubbleView.alpha = 0.6
                   
                } else {
                    self.bubbleView.text = "사진 추가하기"
                }
            })
            .disposed(by: disposeBag)
        
        // 포스트 터치 바인딩
        collectionView.rx.modelSelected(Post.self)
            .asDriver()
            .drive(onNext: { [weak self] post in
                guard let self = self else { return }
                self.startPostDetail(post: post)
                // print("✅ 셀 선택됨: \(post.postId)")
            })
            .disposed(by: disposeBag)
        
        // 오늘 업로드 여부에 따라 카메라 버튼 활성회/비활성화
        homeViewModel.didUserPostToday
            .inverted() // 제일 하단 참고
            .asDriver(onErrorJustReturn: false)
            .drive(cameraBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // 커메라 버튼 투명도 조절
        homeViewModel.didUserPostToday
            .map { $0 ? 0.3 : 1.0 } // ✅ Double 반환
            .asDriver(onErrorJustReturn: 1.0)
            .drive(cameraBtn.rx.alpha) // ✅ Double 바인딩이므로 inverted() 필요 없음
            .disposed(by: disposeBag)
    }
    
    private func makeUI() {
        setupLogoTitle()
        view.backgroundColor = .background

        /// setupUI
        [collectionView, cameraBtn, emptyLabel, bubbleView].forEach {
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
        
        // 말풍선
        NSLayoutConstraint.activate([
            bubbleView.bottomAnchor.constraint(equalTo: cameraBtn.topAnchor, constant: -10),
            bubbleView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
        
        // 멘트
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
        
        /// 좌측 네비게이션 버튼
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "calendar"),
            style: .plain,
            target: self,
            action: #selector(startMembers)
        )
        
        /// 우측 네비게이션 버튼
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.fill"),
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
    
    @objc private func startMembers() {
        coordinator?.startMembers()
    }
    
    /// 카메라 화면 이동
    @objc private func startCamera() {
//        coordinator?.startCamera()
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 📷 사진 촬영
        alert.addAction(UIAlertAction(title: "카메라로 찍기", style: .default) { [weak self] _ in
            self?.coordinator?.startCamera()
        })

        // 🖼️ 앨범에서 선택
        alert.addAction(UIAlertAction(title: "앨범에서 선택", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })

        // ❌ 취소
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }
    
    private func startPostDetail(post: Post) {
        coordinator?.startPostDetail(post: post)
    }
}

// 롱프레스 핸들러
extension HomeViewController {
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return } // 제스처가 시작될 때만 처리

        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location),
              indexPath.item < homeViewModel.posts.value.count else { return }

        let post = homeViewModel.posts.value[indexPath.item]
        
        // 다른 사람 포스트면 삭제 불가
        guard post.userId == homeViewModel.user.value?.uid else {
            print("❌ 다른 사람의 게시물은 삭제할 수 없습니다.")
            return
        }

        let cancel = UIAlertAction(title: "취소", style: .cancel)
        let delete = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.homeViewModel.deletePost(post)
        }
        
        // 삭제 알림 표시
        AlertManager.showAlert(on: self, title: "삭제 확인", message: "이 사진을 삭제하시겠습니까?", actions: [delete, cancel])
    }

}

//extension UICollectionViewFlowLayout {
//    /// 컬렉션 뷰 셀 크기를 자동으로 계산해주는 함수
//    /// - Parameters:
//    ///   - columns: 한 행에 보여줄 셀 개수
//    ///   - spacing: 셀 사이 간격 (기본값 16)
//    ///   - inset: 좌우 마진 (기본값 16)
//    /// - Returns: 계산된 셀 크기
//    func calculateItemSize(columns: Int, spacing: CGFloat = 16, inset: CGFloat = 16) -> CGSize {
//        let screenWidth = UIScreen.main.bounds.width
//        let totalSpacing = spacing * CGFloat(columns - 1) + inset * 2
//        let itemWidth = (screenWidth - totalSpacing) / CGFloat(columns)
//        return CGSize(width: itemWidth, height: itemWidth) // 정사각형 셀
//    }
//}




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
        
        let imageHeight = itemWidth
        let labelHeight: CGFloat = 20 + 14 + 8 // nickname + spacing + bottom margin
        return CGSize(width: itemWidth, height: imageHeight + labelHeight) // 정사각형 셀
    }
}

#Preview {
    UINavigationController(rootViewController: HomeViewController(
        loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()),
        homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao)))))
    
}

// true → false, false → true로 바꾸는 RxSwift용 map 헬퍼 함수
extension ObservableType where Element == Bool {
    func inverted() -> Observable<Bool> {
        return self.map { !$0 }
    }
}

// MARK: - 앨범 선택 관련
extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ 해당 소스타입 사용 불가")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    // 이미지 선택 완료
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            // ✅ 기존 업로드 흐름과 동일하게 처리
            coordinator?.navigateToUpload(image: image, cameraType: .gallary)
        }
    }

    // 선택 취소
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}



class TooltipBubbleView: UIView {
    private let cornerRadius: CGFloat = 20
    private let tipWidth: CGFloat = 20
    private let tipHeight: CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear // 배경은 투명하게
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // ✅ 여기서 실제 말풍선 모양을 그림
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height - tipHeight // 말풍선 본체 높이

        // 시작점: 왼쪽 위 모서리
        path.move(to: CGPoint(x: cornerRadius, y: 0))

        // 상단 라인
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: width, y: cornerRadius),
                          controlPoint: CGPoint(x: width, y: 0))

        // 우측 라인
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: width - cornerRadius, y: height),
                          controlPoint: CGPoint(x: width, y: height))

        // ✅ 아래쪽 중앙에 tip 삼각형 추가
        let tipStartX = (width - tipWidth) / 2
        path.addLine(to: CGPoint(x: tipStartX + tipWidth, y: height))
        path.addLine(to: CGPoint(x: width / 2, y: height + tipHeight))
        path.addLine(to: CGPoint(x: tipStartX, y: height))

        // 좌측 라인
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - cornerRadius),
                          controlPoint: CGPoint(x: 0, y: height))

        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0),
                          controlPoint: CGPoint(x: 0, y: 0))

        // ✅ 색상 채우기
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.gray.cgColor

        layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
        layer.insertSublayer(shapeLayer, at: 0)
    }
}
