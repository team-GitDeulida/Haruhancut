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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(loginViewModel: LoginViewModel) {
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    private lazy var logoutBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.addTarget(self, action: #selector(test), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("홈 화면 이동 완료")
        makeUI()
        
        view.addSubview(logoutBtn)
        logoutBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            logoutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    func makeUI() {
        view.backgroundColor = #colorLiteral(red: 0.09411741048, green: 0.09411782771, blue: 0.102702044, alpha: 1)
        
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
}
