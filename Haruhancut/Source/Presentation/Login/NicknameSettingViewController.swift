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

class NicknameSettingViewController: UIViewController {
    
    // 키보드 가림 해결을 위한 bottom constraint속성
    private var nextButtonBottomConstraint: NSLayoutConstraint?

    private let loginViewModel: LoginViewModel
    
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.text = "사용하실 닉네임을 입력해주세요."
        label.textColor = .white
        label.font = UIFont.hcFont(.bold, size: 20)
        return label
    }()
    
    private lazy var subLabel: UILabel = {
        let label = UILabel()
        label.text = "닉네임은 언제든지 변경할 수 있어요!"
        label.textColor = .gray
        label.font = UIFont.hcFont(.semiBold, size: 15)
        return label
    }()
    
    private lazy var textField: UITextField = {
        let textfield = UITextField()
        textfield.placeholder = "닉네임"
        textfield.textColor = .mainWhite
        textfield.backgroundColor = .Gray500
        textfield.layer.cornerRadius = 10
        
        textfield.addLeftPadding() // 왼쪽에 여백 추가
        textfield.setPlaceholderColor(color: .Gray200) // placeHolder 색상
        
        return textfield
    }()
    
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
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        
        config.title = "다음"
        config.baseBackgroundColor = .mainWhite
        config.baseForegroundColor = .mainBlack
        
        button.configuration = config
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.configurationUpdateHandler = { button in
            var updatedConfig = button.configuration
            updatedConfig?.baseBackgroundColor = button.isHighlighted ? UIColor.lightGray : UIColor.mainWhite
            button.configuration = updatedConfig
        }
        
        // 초기 상태 비활성화
        button.isEnabled = false
        button.alpha = 0.5
        
        button.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        return button
    }()
    
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
        setDelegate()
        makeUI()
        registerForKeyboardNotifications()
    }
    
    // 외부 터치 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }

    func setDelegate() {
        // 텍스트필드의 프로토콜을 사용하기 위해선 사용할 객체를 연결 시켜줘야 한다.(위임)
        // 텍스트필드.대리자 = ViewController의 객체를 담는다
        textField.delegate = self
    }
    
    func makeUI() {
        view.backgroundColor = .background

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
    
    @objc private func didTapNext() {
        view.endEditing(true) // 키보드를 먼저 내림
        print("000000000000000000000000000000")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let birthdayVC = BirthdaySettingViewController(loginViewModel: self.loginViewModel)
            self.navigationController?.pushViewController(birthdayVC, animated: true)
        }
    }
    
}

// 델리게이트 패턴: 객체와 객체간의 커뮤니케이션 (의사소통을 한다)
// 즉. 뷰컨트롤러 대신에 일을 수행하고 그 결과값을 전달할 수 있다
extension NicknameSettingViewController: UITextFieldDelegate {
    // return키 입력시 키보드 내려감
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // 텍스트가 빈 문자열이 아닐떄만 다음 버튼 활성화
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 최종적으로 입력될 텍스트 구하기
        if let currentText = textField.text as NSString? {
            let updatedText = currentText.replacingCharacters(in: range, with: string)
            let isNotEmpty = !updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            nextButton.isEnabled = isNotEmpty
            nextButton.alpha = isNotEmpty ? 1.0 : 0.5
        }
        return true
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
    NicknameSettingViewController(loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()))
}

