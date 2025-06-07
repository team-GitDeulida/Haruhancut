//  SettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/28/25.
//

import UIKit
import FirebaseAuth
import RxSwift

final class SettingViewController: UIViewController {
    
    private let disposeBaag = DisposeBag()
    
    weak var coordinator: HomeCoordinator?

    private let viewModel = SettingViewModel()
    private let homeViewModel: HomeViewModelType
    
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Component
    private lazy var logoutBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        return button
    }()
    
    private lazy var mySwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = .systemBlue
        sw.isOn = false
        return sw
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
        bindViewModel()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        [logoutBtn, mySwitch].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            logoutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            mySwitch.topAnchor.constraint(equalTo: logoutBtn.bottomAnchor, constant: 20),
            mySwitch.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        // Input: 버튼 탭 이벤트를 viewModel로 전달
        let input = SettingViewModel.Input(logoutTapped: logoutBtn.rx.tap.asObservable(),
                                           switchToggled: mySwitch.rx.isOn
                                                            .distinctUntilChanged() // 연속 같은 값은 무시
                                                            .asObservable()
        )
        
        // Output: transform으로부터 결과 스트림 반환
        let output = viewModel.transform(input: input)
            
        // Output에 따라 UI 처리
        output.logoutResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    print("로그아웃 성공")
                    self.coordinator?.showLogin()
                case .failure(let error):
                    print("로그아웃 실패: \(error.localizedDescription)")
                }
                
            }).disposed(by: disposeBaag)
    }
}

#Preview {
    SettingViewController(homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0]))
}

