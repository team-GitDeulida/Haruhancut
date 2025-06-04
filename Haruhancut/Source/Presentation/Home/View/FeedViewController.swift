//
//  FeedViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/4/25.
//

import UIKit
import RxSwift

final class FeedViewController: UIViewController {
    
    /// 이벤트 콜백 (Home에서 알람 울리기)
    var onPresentAlert: ((UIAlertController) -> Void)?
    
    /// 이벤트 콜백 (Home에서 앨범 띄우기)
    var onPresent: ((UIViewController) -> Void)?
    
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let disposeBag = DisposeBag()
    
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeUI()
        constraints()
        bindViewModel()
        setupLongPressGesture()
    }
    
    private func makeUI() {
        view.backgroundColor = .background

        [collectionView, cameraBtn, bubbleView, emptyLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            // 컬렉션뷰
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: cameraBtn.topAnchor, constant: -20),

            // 카메라 버튼
            cameraBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            cameraBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // 말풍선
            bubbleView.bottomAnchor.constraint(equalTo: cameraBtn.topAnchor, constant: -10),
            bubbleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // emptyLabel (가운데 정렬)
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50.scaled)
        ])
    }
    
    // 비동기 데이터 받아오면 UI에 반영
    private func bindViewModel() {
        // 그룹 이름 바인딩
//        homeViewModel.transform().groupName
//            .drive(onNext: { [weak self] text in
//                guard let self = self else { return }
//                self.segmentTabBar.setSegmentTitle(text, at: 0)
//            })
//            .disposed(by: disposeBag)
        
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
    
    /// 포스트 화면 이동
    private func startPostDetail(post: Post) {
        coordinator?.startPostDetail(post: post)
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

        /// 직접 present 대신 콜백 위임!
        if let presentAlert = onPresentAlert {
            presentAlert(alert)
        } else {
            // 혹시나 없으면 fallback (단, 이 경우는 hierarchy 경고 가능성 있음)
            present(alert, animated: true)
        }
    }
}

// MARK: - 앨범 선택 관련
extension FeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ 해당 소스타입 사용 불가")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        
        
        // present(picker, animated: true)
        
        // 부모에게 위임해서 present!
        if let presentAction = onPresent {
            presentAction(picker)
        } else {
            // 없으면 fallback (이 경우 경고 발생 가능)
            present(picker, animated: true)
        }
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

// MARK: - 롱프레스 핸들러
extension FeedViewController {
    
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
        
        let alert = UIAlertController(title: "삭제 확인", message: "이 사진을 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(delete)
        alert.addAction(cancel)
        if let presentAlert = onPresentAlert {
            presentAlert(alert)
        }
        
        // 삭제 알림 표시
        // AlertManager.showAlert(on: self, title: "삭제 확인", message: "이 사진을 삭제하시겠습니까?", actions: [delete, cancel])
    }

}
