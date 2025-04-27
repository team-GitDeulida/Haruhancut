//  ProfileViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import UIKit
import FirebaseAuth
import RxSwift

final class ProfileViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    weak var coordinator: HomeCoordinator?

    private let viewModel = ProfileViewModel()
    
    // MARK: - UI Component
    private lazy var logoutBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.addTarget(self, action: #selector(logout), for: .touchUpInside)
        return button
    }()
    
    private lazy var testBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test", for: .normal)
        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .mainBlack
        
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
    
    @objc func logout() {
        do {
            UserDefaultsManager.shared.removeUser()
            UserDefaultsManager.shared.removeGroup()
            try Auth.auth().signOut()
            print("로그아웃 성공")
            coordinator?.showLogin()
            
        } catch let signOutError as NSError {
            print("로그아웃 실패: %@", signOutError)
        }
    }
}

#Preview {
    ProfileViewController()
}
