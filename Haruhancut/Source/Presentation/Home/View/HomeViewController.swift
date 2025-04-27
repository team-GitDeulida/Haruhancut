//
//  HomeViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

/*
 reference
 - https://dmtopolog.com/navigation-bar-customization/ (navigation bar)
 
 
 
 ContentMode    설명
 .scaleAspectFit    이미지 비율 유지하면서 버튼 안에 "모두" 들어오게
 .scaleAspectFill    이미지가 버튼을 "가득" 채우게 (비율은 유지하지만 잘릴 수도 있음)
 .center    가운데 정렬만 하고 크기 안바꿈
 .top, .bottom, .left, .right    방향 맞춰서 위치만 변경
 
 */

import UIKit
import FirebaseAuth
import RxSwift

final class HomeViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    
    private let loginViewModel: LoginViewModel
    private let homeViewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Component
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "하루한컷"
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()
    
    private lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(
    loginViewModel: LoginViewModel,
    homeViewModel: HomeViewModel
    ) {
        self.loginViewModel = loginViewModel
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        // bindViewModel()
    }
    
    func makeUI() {
        setupLogoTitle()
        view.backgroundColor = .background
        
        view.addSubview(cameraBtn)
        cameraBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 위치
            cameraBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            cameraBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
        ])
        
    }
    
    func setupLogoTitle() {
        /// 네비게이션 버튼 색상
        self.navigationController?.navigationBar.tintColor = .mainWhite
        
        /// 네비게이션 제목
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
    @objc func startProfile() {
        coordinator?.startProfile()
    }
}
