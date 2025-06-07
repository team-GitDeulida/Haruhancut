//  NicknameChangeViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/7/25.
//

import UIKit
import RxSwift

final class NicknameChangeViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?
    private let loginViewModel: LoginViewModelType
    private var endButtonBottomConstraint: NSLayoutConstraint?
    private let disposeBag = DisposeBag()
    
    
    // MARK: - UI Component
    private lazy var mainLabel: UILabel = HCLabel(type: .main(text: "변경하실 닉네임을 입력해주세요."))

    private lazy var subLabel: UILabel = HCLabel(type: .sub(text: "닉네임은 언제든지 변경할 수 있어요!"))
    
    private lazy var textField: UITextField = HCTextField(placeholder: "닉네임")
    
    private lazy var labelStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel,
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually // 모든 뷰가 동일한 크기
        // 뷰의 크기를 축 반대 방향으로 꽉 채운다
        // 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    
    private lazy var endButton: UIButton = {
        let button = HCNextButton(title: "완료")
        // button.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        return button
    }()
    
    init(loginViewModel: LoginViewModelType) {
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForKeyboardNotifications()
        makeUI()
        constraints()
        bindViewModel()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        // MARK: - 커스텀 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "뒤로가기"
        navigationItem.backBarButtonItem = backItem
        navigationController?.navigationBar.tintColor = .mainWhite
        
        // MARK: - LabelStack
        [labelStackView, textField, endButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        
        endButtonBottomConstraint = endButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        endButtonBottomConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            // labelStackView
            labelStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            labelStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // textField
            textField.topAnchor.constraint(equalTo: labelStackView.bottomAnchor, constant: 30),
            textField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textField.heightAnchor.constraint(equalToConstant: 50),
            
            // endButton
            endButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            endButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            endButton.heightAnchor.constraint(equalToConstant: 50)
            
        ])
    }
    
    private func bindViewModel() {
        let input = LoginViewModel.NicknameChangeInput(nicknameText: textField.rx.text.orEmpty.asObservable(), endBtnTapped: endButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        bindViewModelOutput(output: output)
    }
    
    private func bindViewModelOutput(output: LoginViewModel.NicknameChangeOutput) {
        output.isNicknameValid
            /// 닉네임 유효성에 따라 버튼의 UI 상태 업데이트
            .drive(onNext: { [weak self] isValid in
                guard let self = self else { return }
                self.endButton.isEnabled = isValid
                self.endButton.alpha = isValid ? 1.0 : 0.5
            }).disposed(by: disposeBag)
        
        output.nicknameChangeResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    // print("닉네임 변경 실패:", error)
                    AlertManager.showAlert(on: self, title: "에러", message: "닉네임 변경 실패")
                }
            })
            .disposed(by: disposeBag)
        
        /// return키 입력시 키보드 내려감
        textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            })
            .disposed(by: disposeBag)
    }
}

#Preview {
    NicknameChangeViewController(loginViewModel: StubLoginViewModel())
}

extension NicknameChangeViewController {
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let bottomInset = keyboardFrame.height - view.safeAreaInsets.bottom
        endButtonBottomConstraint?.constant = -bottomInset - 10
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        endButtonBottomConstraint?.constant = -10
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
