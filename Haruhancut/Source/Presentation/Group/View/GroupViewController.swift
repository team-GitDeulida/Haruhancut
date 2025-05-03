//
//  GroupViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/18/25.
//

import UIKit
import RxSwift

final class GroupViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let groupViewModel: GroupViewModel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(groupViewModel: GroupViewModel) {
        self.groupViewModel = groupViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    weak var coordinator: HomeCoordinator?
    
    // MARK: - UI Conponents
    
    // 타이틀
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "하루한컷"
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()
        
    // 설명
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        // label.text = "닉네임 님이 가입하신 모임은\n총 0개에요!"
        label.text = "가족에게 받은\n그룹 초대 코드가 있으신가요?"
        label.numberOfLines = 0
        label.textColor = .mainWhite
        label.font = UIFont.hcFont(.bold, size: 20)
        return label
    }()
    
    // 입장 label
    private lazy var enterButton: HCGroupButton = {
        let button = HCGroupButton(
            topText: "초대 코드를 받았다면",
            bottomText: "가족 방 입장하기",
            rightImage: "arrow.right")
        return button
    }()
    
    // 초대 label
    private lazy var hostButton: UIButton = {
        let button = HCGroupButton(
            topText: "초대 코드가 없다면",
            bottomText: "가족 방 만들기",
            rightImage: "arrow.right")
        return button
    }()

    // 입장초대 viewStack
    private lazy var viewStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            enterButton,
            hostButton
        ])
        stack.spacing = 20
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        rxBtnTap()
    }
    
    // MARK: - Setup UI
    private func makeUI() {
        setupLogoTitle()
        /// 커스텀 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "뒤로가기"
        navigationItem.backBarButtonItem = backItem
        navigationController?.navigationBar.tintColor = .mainWhite
        
        // 배경 색상
        view.backgroundColor = .background
        
        // MARK: - mainLabel
        view.addSubview(mainLabel)
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            mainLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
        
        // MARK: - viewStack
        view.addSubview(viewStackView)
        viewStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 위치
            viewStackView.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 50),
            viewStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 크기
            viewStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            viewStackView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    func setupLogoTitle() {
        self.navigationItem.titleView = titleLabel
//        let titleLabel: UILabel = {
//            $0.attributedText =
//                .RLAttributedString(
//                    text: "Runlog",
//                    font: .Logo2,
//                    color: .LightGreen
//                )
//            $0.textAlignment = .center
//        }
//        topViewController?.navigationItem.titleView = titleLabel
    }
    
    func rxBtnTap() {
        
        // Coordinator 트리거
        enterButton.rx.tap
            .bind { [weak self] in
                self?.coordinator?.startGroupEnter()
            }
            .disposed(by: disposeBag)

        hostButton.rx.tap
            .bind { [weak self] in
                self?.coordinator?.startGroupHost()
            }
            .disposed(by: disposeBag)
    }

}

#Preview {
    GroupViewController(groupViewModel: GroupViewModel(loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()), groupUsecase: GroupUsecase(repository: GroupRepository(firebaseAuthManager: FirebaseAuthManager.shared)), homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao)))))
}
