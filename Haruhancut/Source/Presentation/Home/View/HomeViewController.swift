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
    
    // MARK: - UI
    
    private let segmentedBar: CustomSegmentedBarView = {
       let segment = CustomSegmentedBarView(items: ["피드", "캘린더"])
        // segment.
        return segment
    }()
    
    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        vc.setViewControllers([self.dataViewControllers[0]], direction: .forward, animated: true)
        vc.delegate = self
        vc.dataSource = self
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        return vc
    }()
    
    /// 현재 선택된 세그먼트 인덱스
    var currentPage: Int = 0 {
        didSet {
            let direction: UIPageViewController.NavigationDirection = oldValue <= self.currentPage ? .forward : .reverse
            self.pageViewController.setViewControllers(
                [dataViewControllers[self.currentPage]],
                direction: direction,
                animated: true,
                completion: nil
            )
        }
    }
    
    private lazy var feedViewController: FeedViewController = {
        let vc = FeedViewController(homeViewModel: homeViewModel)
        vc.coordinator = self.coordinator
        
        // Alert present는 항상 Home에서!
        vc.onPresentAlert = { [weak self] alert in
            self?.present(alert, animated: true)
        }
        
        // 이미지피커, 기타 present는 onPresent
        vc.onPresent = { [weak self] presentedVC in
            self?.present(presentedVC, animated: true)
        }
        
        return vc
    }()
    
    private lazy var calendarViewController: CalendarViewController = {
        let vc = CalendarViewController(homeViewModel: homeViewModel)
        vc.onPresent = { [weak self] presentedVC in
            self?.present(presentedVC, animated: true)
        }
        return vc
    }()
    
    var dataViewControllers: [UIViewController] { [feedViewController, calendarViewController] }
    
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
        // print("✅ homeVC - \(homeViewModel.posts.value)")
    }
    
    private func makeUI() {
        setupLogoTitle()
        view.backgroundColor = .background
        
        [segmentedBar, pageViewController.view].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        segmentedBar.segmentedControl.addTarget(self, action: #selector(changeValue(control:)), for: .valueChanged)
        segmentedBar.segmentedControl.selectedSegmentIndex = 0
        changeValue(control: segmentedBar.segmentedControl)
    }

    /// 네비게이션 바 설정
    private func setupLogoTitle() {
        /// 네비게이션 버튼 색상
        self.navigationController?.navigationBar.tintColor = .mainWhite
        
        /// 네비게이션 제목
        segmentedBar.sizeToFit() // 글자 길이에 맞게 label 크기 조정
        self.navigationItem.titleView = segmentedBar
        
        /// 좌측 네비게이션 버튼
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
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
    
    /// 그룹 화면 이동
    @objc private func startMembers() {
        coordinator?.startMembers()
    }
}

extension HomeViewController {
    /// 세그먼트 변경 이벤트 핸들러
    @objc private func changeValue(control: UISegmentedControl) {
        self.currentPage = control.selectedSegmentIndex
        segmentedBar.moveUnderline(animated: true)
    }
}

extension HomeViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.dataViewControllers.firstIndex(of: viewController), index - 1 >= 0 else { return nil }
        return self.dataViewControllers[index - 1]
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.dataViewControllers.firstIndex(of: viewController), index + 1 < self.dataViewControllers.count else { return nil }
        return self.dataViewControllers[index + 1]
    }
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = pageViewController.viewControllers?[0], let index = self.dataViewControllers.firstIndex(of: viewController) else { return }
        self.currentPage = index
        segmentedBar.segmentedControl.selectedSegmentIndex = index
        segmentedBar.moveUnderline(animated: true)
    }
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

#Preview {
    UINavigationController(rootViewController: HomeViewController(
        loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()),
        homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao)))))
    
}







