//
//  HomeViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

import UIKit
import FirebaseAuth

final class HomeViewController: UIViewController {
    
    private let loginViewModel: LoginViewModel
    private let homeViewModel: HomeViewModel
    
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
    
    private lazy var testBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test", for: .normal)
        return button
    }()
    
    private lazy var logoutBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.addTarget(self, action: #selector(test), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        bind()
    }
    
    func makeUI() {
        view.backgroundColor = .background
        
        view.addSubview(logoutBtn)
        logoutBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            logoutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        view.addSubview(testBtn)
        testBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            testBtn.topAnchor.constraint(equalTo: logoutBtn.bottomAnchor, constant: 50),
            testBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func test() {
        do {
            UserDefaultsManager.shared.clearSignupStatus()
            try Auth.auth().signOut()
            print("로그아웃 성공")
            
            // SceneDelegate에서 로그인 루트로 변경
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.makeLoginRoot()
            }
            
        } catch let signOutError as NSError {
            print("로그아웃 실패: %@", signOutError)
        }
    }
    
    private func bind() {
        homeViewModel.bindButtonTap(tap: testBtn.rx.tap.asObservable())
    }
}
