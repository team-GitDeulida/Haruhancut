//
//  NicknameSettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//
/*
 https://ios-daniel-yang.tistory.com/entry/UITextField
 https://ios-development.tistory.com/369
 */

import UIKit
import RxSwift
import RxCocoa

final class NicknameSettingViewController: UIViewController {
    weak var coordinator: LoginFlowCoordinator?
    
    private let disposeBag = DisposeBag()
    
    // 키보드 가림 해결을 위한 bottom constraint속성
    private var nextButtonBottomConstraint: NSLayoutConstraint?
    
    private let loginViewModel: LoginViewModel
    
    private lazy var mainLabel: UILabel = HCLabel(type: .main(text: "사용하실 닉네임을 입력해주세요."))

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
    
    private lazy var nextButton: UIButton = HCNextButton(title: "다음")
    
    init(loginViewModel: LoginViewModel) {
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        registerForKeyboardNotifications()
        bindViewModel()
    }
    
    // 외부 터치 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    private func makeUI() {
        view.backgroundColor = .background
        
        // MARK: - 커스텀 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "뒤로가기"
        navigationItem.backBarButtonItem = backItem
        navigationController?.navigationBar.tintColor = .mainWhite
        
        // MARK: - labelStack
        // 1. view에 버튼 추가
        view.addSubview(labelStackView)
        
        // 2. 오토레이아웃 활성화
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. 오토레이아웃 제약 추가
        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),        // y축 위치
            labelStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20) // x축 위치
        ])
        
        // MARK: - textField
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: labelStackView.bottomAnchor, constant: 30),  // y축 위치
            textField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor), // x축 위치
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20), // 좌우 패딩
            textField.heightAnchor.constraint(equalToConstant: 50) // 버튼 높이
        ])
        
        // MARK: - NextButtonn
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 키보드에 의해 다음 버튼 가림을 막기 위한 방법
        nextButtonBottomConstraint = nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        nextButtonBottomConstraint?.isActive = true
        NSLayoutConstraint.activate([
            //nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10), // y축 위치
            nextButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),              // x축 위치
            
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),// 좌우 패딩
            nextButton.heightAnchor.constraint(equalToConstant: 50) // 버튼 높이
        ])
    }
    
    /// view -> viewModel로 Input 전달(UI 이벤트)
    private func bindViewModel() {
        let input = LoginViewModel.NicknameInput(nicknameText: textField.rx.text.orEmpty.asObservable(), nextBtnTapped: nextButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        bindViewModelOutput(output: output)
    }
    
    /// viewModel 에서 나온 Output을 View(UI)에 바인딩
    private func bindViewModelOutput(output: LoginViewModel.NicknameOutput) {
        
        /// viewModel이 Output으로 방출한 결과를 viewController가 구독
        /// 다음 버튼이 눌렸음을 알려주는 이벤트 스트림
        /// 생일 화면으로 이동하라고 방출한 Output 이벤트 스트림 을 구독
        output.moveToBirthday
            /// 이 이벤트가 방출되었을 때 실행할 동작을 등록(=구독)
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.coordinator?.showBirthday()
                }
                /// 구독이 메모리에서 자동으로 해제되도록 설정
            }).disposed(by: disposeBag)
        
        /// 닉네임 유효성 검사에 따라 버튼 활성화
        output.isNicknameValid
            /// 닉네임 유효성에 따라 버튼의 UI 상태 업데이트
            .drive(onNext: { [weak self] isValid in
                guard let self = self else { return }
                self.nextButton.isEnabled = isValid
                self.nextButton.alpha = isValid ? 1.0 : 0.5
            }).disposed(by: disposeBag)
        
        /// return키 입력시 키보드 내려감
        textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - 키보드 알림
extension NicknameSettingViewController {
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
        nextButtonBottomConstraint?.constant = -bottomInset - 10
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        nextButtonBottomConstraint?.constant = -10
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

#Preview {
    // NicknameSettingViewController(loginViewModel: LoginViewModel())
    NicknameSettingViewController(loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StupGroupUsecase()))
}

