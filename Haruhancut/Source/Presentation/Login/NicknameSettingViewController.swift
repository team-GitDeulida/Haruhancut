//
//  NicknameSettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

import UIKit

class NicknameSettingViewController: UIViewController {
    
    private let loginViewModel: LoginViewModel
    
    init(loginViewModel: LoginViewModel) {
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
        if let token = loginViewModel.token {
            print("토큰 옮기기 성공: \(token)")
        } else {
            print("토큰이 아직 없습니다.")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    private lazy var btn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        return button
    }()
    
    func makeUI() {
        view.backgroundColor = .background
        
        // 1. view에 버튼 추가
        view.addSubview(btn)
        
        // 2. 오토레이아웃 활성화
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. 오토레이아웃 제약 추가
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func didTapNext() {
        self.navigationController?.setViewControllers([
            HomeViewController()
        ], animated: true)
    }
}

#Preview {
    NicknameSettingViewController(loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()))
}
