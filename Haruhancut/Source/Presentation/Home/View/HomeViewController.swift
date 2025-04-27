//
//  HomeViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

/*
 reference
 - https://dmtopolog.com/navigation-bar-customization/ (navigation bar)
 */

import UIKit
import FirebaseAuth
import RxSwift

final class HomeViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    
    private let loginViewModel: LoginViewModel
    private let homeViewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    
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
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "하루한컷"
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        // bindViewModel()
    }
    
    func makeUI() {
        setupLogoTitle()
        view.backgroundColor = .background
    }
    
    func setupLogoTitle() {
        self.navigationController?.navigationBar.tintColor = .mainWhite // 버튼 색
        
        self.navigationItem.titleView = titleLabel
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person"),
            style: .plain,
            target: self,
            action: #selector(startProfile)
        )
    }
    
    /// Rx처리가 오히려 오버 엔지니어링이라고 판단됨
    @objc func startProfile() {
        coordinator?.startProfile()
    }
}
