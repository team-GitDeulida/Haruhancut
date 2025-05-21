//  GroupDetailViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/25/25.
//

import UIKit
import RxSwift

final class GroupEnterViewController: UIViewController {
    
    private let groupViewModel: GroupViewModel
    
    init(groupViewModel: GroupViewModel) {
        self.groupViewModel = groupViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let disposeBag = DisposeBag()

    weak var coordinator: HomeCoordinator?
    
    // 키보드 가림 해결을 위한 bottom constraint속성
    private var endButtonBottomConstraint: NSLayoutConstraint?
    
    // MARK: - UI Components
    private lazy var mainLabel: HCLabel = {
        let label = HCLabel(type: .main(text: "그룹 초대 코드를 입력해 주세요"))
        return label
    }()
    
    private lazy var textField: HCTextField = {
        let textField = HCTextField(placeholder: "그룹 초대 코드를 입력해 주세요")
        return textField
    }()
    
    private lazy var endButton: HCNextButton = {
        let button = HCNextButton(title: "완료")
        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        bindViewModel()
        registerKeyboardNotifications(bottomConstraint: endButtonBottomConstraint!)
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        print("Enter View")
        
        view.addSubview(mainLabel)
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            mainLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
        
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 30),  // y축 위치
            textField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor), // x축 위치
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20), // 좌우 패딩
            textField.heightAnchor.constraint(equalToConstant: 50) // 버튼 높이
        ])
        
        view.addSubview(endButton)
        endButton.translatesAutoresizingMaskIntoConstraints = false
        endButtonBottomConstraint = endButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        endButtonBottomConstraint?.isActive = true
        NSLayoutConstraint.activate([
            endButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            endButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),// 좌우 패딩
            endButton.heightAnchor.constraint(equalToConstant: 50) // 버튼 높이
        ])
        
        
    }
    
    private func bindViewModel() {
        /// return키 입력시 키보드 내려감
        textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        
        // 초대 코드 입력 후 완료 버튼 클릭
        let input = GroupViewModel.GroupEnterInput(
            inviteCodeText: textField.rx.text.orEmpty.asObservable(),
            endButtonTapped: endButton.rx.tap.asObservable())
        
        let output = groupViewModel.transformEnter(input: input)
        output.enterResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.coordinator?.startHome()
                case .failure:
                    self.showErrorAlert(message: "초대 코드가 유효하지 않습니다.")
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: 외부 터치 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    // MARK: - Alert
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "입장 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

#Preview {
    GroupEnterViewController(groupViewModel: GroupViewModel(loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()),
                                                            groupUsecase: StubGroupUsecase(), homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao)))))
}


//#Preview {
//    GroupEnterViewController(groupViewModel: GroupViewModel(loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()), groupUsecase: GroupUsecase(repository: GroupRepository(firebaseAuthManager: FirebaseAuthManager.shared)), homeViewModel: <#HomeViewModel#>))
//}
