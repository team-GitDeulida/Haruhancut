//
//  BirthdaySettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/14/25.
//
/*
 https://ios-daniel-yang.tistory.com/entry/SwiftTIL-11-TextField와-DatePicker를-같이-사용해보자
 
 -[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:]  perform input operation requires a valid sessionID. inputModality = Keyboard, inputOperation = <null selector>, customInfoType = UIEmojiSearchOperations
 
 */

import UIKit
import RxSwift
import RxCocoa

final class BirthdaySettingViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let loginViewModel: LoginViewModel
    
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.text = "\(loginViewModel.user?.nickname ?? "닉네임") 님의 생년월일을 알려주세요."
        label.textColor = .mainWhite
        label.font = UIFont.hcFont(.bold, size: 20)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var subLabel: UILabel = {
        let label = UILabel()
        label.text = "가족들이 함께 생일을 축하할 수 있어요!"
        label.textColor = .gray
        label.font = UIFont.hcFont(.semiBold, size: 15)
        return label
    }()
    
    private lazy var textField: UITextField = HCTextField(placeholder: "2000.11.11")
    
    private lazy var labelStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually // 모든 뷰가 동일한 크기
        // 뷰의 크기를 축 반대 방향으로 꽉 채운다
        // 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    
    private lazy var nextButton: UIButton = HCNextButton(title: "완료")
    
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
        bindViewModel()
    }
    
    private func makeUI() {
        view.backgroundColor = .background

        // MARK: - labelStack setup
        // 1. view에 버튼 추가
        view.addSubview(labelStackView)
        
        // 2. 오토레이아웃 활성화
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. 오토레이아웃 제약 추가
        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),        // y축 위치
            labelStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20) // x축 위치
        ])
        
        // MARK: - textField setup
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: labelStackView.bottomAnchor, constant: 30),  // y축 위치
            textField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor), // x축 위치
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20), // 좌우 패딩
            textField.heightAnchor.constraint(equalToConstant: 50) // 버튼 높이
        ])
        setupDatePicker()
        
        // MARK: - NextButtonn setup
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10), // y축 위치
            nextButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),              // x축 위치
            
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),// 좌우 패딩
            nextButton.heightAnchor.constraint(equalToConstant: 50) // 버튼 높이
        ])
    }
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko-KR")
        picker.timeZone = TimeZone(identifier: "Asia/Seoul")
        return picker
    }()
    
    private func bindViewModel() {
        let input = LoginViewModel.Input.init(
            kakaoLoginTapped: .never(),
            appleLoginTapped: .never(),
            nicknameText: .never(),
            nicknameNextBtnTapped: .never(),
            birthdayDate: datePicker.rx.date.asObservable(),
            birthdayNextTapped: nextButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        bindViewModelOutput(output: output)
    }
    
    private func bindViewModelOutput(output: LoginViewModel.Output) {
        
        // 회원가입 요청
//        output.moveToHome
//            .drive(onNext: { [weak self] in
//                guard let self = self else { return }
//                self.view.endEditing(true)
//            })
//            .disposed(by: disposeBag)
        
        // 회원가입 결과 처리
        output.signUpResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.view.endEditing(true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.navigationController?.setViewControllers([HomeViewController(loginViewModel: self.loginViewModel, homeViewModel: HomeViewModel())], animated: true)
                    }
                case .failure(let error):
                    // 실패 알림 등 추가
                    print("❌ [VC] 회원가입 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
        
        
    }
    
}

extension BirthdaySettingViewController {

    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "ko-KR")
        datePicker.addTarget(self, action: #selector(dateChange), for: .valueChanged)
        
        // ✅ 핵심: inputView를 datePicker로 지정
        textField.inputView = datePicker
        
        // ✅ 툴바를 inputAccessoryView로 설정
        textField.inputAccessoryView = createToolbar()

        // ✅ 초기값을 2000년 1월 1일로 설정
        let defaultDate = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
        datePicker.date = defaultDate
        textField.text = defaultDate.toKoreanDateString()
    }
    
    private func showDatePickerAlert() {
        let alert = UIAlertController(title: "생년월일 선택", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko-KR")
        picker.date = datePicker.date // 기존 값 유지
        picker.frame = CGRect(x: 0, y: 30, width: 270, height: 216)

        alert.view.addSubview(picker)

        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.datePicker.date = picker.date
            self.textField.text = picker.date.toKoreanDateString()
            self.loginViewModel.user?.birthdayDate = picker.date
        }))

        present(alert, animated: true)
    }

    @objc private func dateChange(_ sender: UIDatePicker) {
        textField.text = sender.date.toKoreanDateString()
        loginViewModel.user?.birthdayDate = sender.date
    }
    
    // 툴바 추가
    private func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(donePressed))
        
        // "완료" 버튼을 오른쪽으로 보내기
        toolbar.setItems([flexibleSpace, doneButton], animated: true)

        return toolbar
    }

    @objc private func donePressed() {
        textField.resignFirstResponder()
    }
}

#Preview {
    BirthdaySettingViewController(
        loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()))
}
