//  OnboardingViewController.swift
//  UIComponentTutorial
//
//  Created by 김동현 on 6/11/25.
//

/*
 private let    초기화 이후 절대 변경 X, 상수로 고정되는 UI나 데이터
 private lazy var    초기화에 다른 프로퍼티가 필요한 경우, 지연 초기화
 private var    값이 변할 수 있는 경우 (상태 값, 업데이트 등)
 https://ios-daniel-yang.tistory.com/entry/Swift-TIL-37-UIPageViewController를-사용하여-튜토리얼-화면을-만들기
 */
import UIKit
import ScaleKit
/*
final class StartViewController: UIViewController {
    
    // MARK: - UI Component

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkToturialRul()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .white
    }
}

// MARK: - 튜토리얼 유뮤에 따라 온보딩 화면 생성
extension StartViewController {
    func checkToturialRul() {
        let userDefault = UserDefaults.standard
        if userDefault.bool(forKey: "Tutorial") == false {
            let onboardingVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            onboardingVC.modalPresentationStyle = .fullScreen
            present(onboardingVC, animated: false)
        }
    }
}
 */

final class OnboardingViewController: UIPageViewController {
    
    // MARK: - property
    private var pages: [UIViewController] = []
    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .black
        pc.pageIndicatorTintColor = .lightGray
        return pc
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .hcFont(.medium, size: 18)
        button.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [pageControl, nextButton])
        sv.axis = .vertical
        sv.spacing = 10.scaled
        sv.alignment = .center
        return sv
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .white
        let page1 = PageContentsViewController(imageName: "1",
                                               title: "하루 한컷",
                                               subTitle: "가족과의 하루를 \n한 장의 사진으로 나눠보세요.")
        let page2 = PageContentsViewController(imageName: "3",
                                               title: "일상 공유",
                                               subTitle: "매일의 이야기를 함께 나눠요.\n")
        let page3 = PageContentsViewController(imageName: "4",
                                               title: "기록을 한눈에",
                                               subTitle: "달력으로 사진을 돌아볼 수 있어요.\n")
        
        let page4 = PageContentsViewController(imageName: "5",
                                               title: "나의 이야기, 나만의 공간에",
                                               subTitle: "내가 남긴 기록을 한 곳에 담아보세요.\n")
        pages.append(contentsOf: [page1, page2, page3, page4])
        
        // dataSource 화면에 보여질 뷰컨트롤러들을 관리
        self.dataSource = self
        self.delegate = self
        
        // UIPageViewController에서 처음 보여질 뷰컨트롤러 설정(첫 page)
        self.setViewControllers([pages[0]], direction: .forward, animated: true)
        
        view.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = pages.count
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            hStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10.scaled),
            hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 105.scaled),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -105.scaled),
            nextButton.heightAnchor.constraint(equalToConstant: 50.scaled)
        ])
    }
    
    @objc
    private func didTapNext() {
        guard let currentVC = viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentVC) else { return }

        let nextIndex = currentIndex + 1

        if nextIndex < pages.count {
            // 다음 페이지로 이동
            setViewControllers([pages[nextIndex]], direction: .forward, animated: true)
            pageControl.currentPage = nextIndex
            
            // 버튼 텍스트 업데이트
            if nextIndex == pages.count - 1 {
                nextButton.setTitle("완료", for: .normal)
            } else {
                nextButton.setTitle("다음", for: .normal)
            }
            
        } else {
            dismiss(animated: true, completion: nil)
            UserDefaults.standard.set(true, forKey: "Tutorial")
            
            /*
            // 마지막 페이지일 경우 → 다음 화면으로 이동 (예: 로그인 화면)
            UserDefaults.standard.set(true, forKey: "Tutorial")

            let loginVC = LoginViewController() // ✅ 당신의 앱에 맞는 ViewController로 변경하세요
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: true)
             */
        }
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    // 이전 뷰 컨트롤러 리턴(우측 -> 좌측 슬라이드 제스처)
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // 현재 vc 인덱스 구하기
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        // 현재 인덱스가 0보다 크다면 다음 줄로 이동
        guard currentIndex > 0 else { return nil }
        return pages[currentIndex - 1]
    }
    
    // 다음 뷰 컨트롤러 화면(좌측 -> 우측 슬라이드 제스처)
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // 현재 vc 인덱스 구하기
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        // 현재 인덱스가 마지막 인덱스보다 작을 때만 다음줄로 이동
        guard currentIndex < (pages.count - 1) else { return nil }
        return pages[currentIndex + 1]
    }
    
    
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed,
                  let currentVC = viewControllers?.first,
                  let index = pages.firstIndex(of: currentVC) else { return }
            pageControl.currentPage = index
        
        
            if index == pages.count - 1 {
                nextButton.setTitle("완료", for: .normal)
            } else {
                nextButton.setTitle("다음", for: .normal)
            }
        }
}


final class PageContentsViewController: UIViewController {
    
    // MARK: - UI Component
    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [imageView, titleLabel, subTitleLabel])
        sv.axis = .vertical
        sv.spacing = 14.scaled
        sv.alignment = .center
        return sv
    }()
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .hcFont(.extraBold, size: 30)
        label.textColor = .black
        // label.font = .preferredFont(forTextStyle: .title1)
        // label.font = .systemFont(ofSize: 30.scaled)
       
        return label
    }()
    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .hcFont(.light, size: 20.scaled)
        //label.textColor = .darkGray
        return label
    } ()
    
    
    init(imageName: String, title: String, subTitle: String) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = UIImage(named: imageName)
        titleLabel.text = title
        subTitleLabel.text = subTitle
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
    }

    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .white
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(20.scaled, after: imageView)
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            
            // stackView - 중앙 정렬 + 좌우 여백
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.scaled),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -10.scaled),  // inset 50 * 2
            
            // imageView - view 기준으로 60%
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        ])
    }
}

#Preview {
    OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
}
