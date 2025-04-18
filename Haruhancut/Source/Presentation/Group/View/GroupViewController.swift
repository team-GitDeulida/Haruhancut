//
//  GroupViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/18/25.
//

import UIKit

final class GroupViewController: UIViewController {
    
    // MARK: - UI Conponents
    
    // 타이틀
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "하루한컷"
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()
    
    // 로고
//    private lazy var logoLabel: UILabel = {
//        let label = UILabel()
//        label.text = "하루한컷"
//        label.font = UIFont.hcFont(.bold, size: 20)
//        label.textColor = .mainWhite
//        return label
//    }()
    
    // 설명
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.text = "닉네임 님이 가입하신 모임은\n총 0개에요!"
        label.numberOfLines = 0
        label.textColor = .mainWhite
        label.font = UIFont.hcFont(.bold, size: 20)
        return label
    }()
    
    // 입장 label
    private lazy var enterView: UIView = {
        let view = UIView()
        view.backgroundColor = .Gray500
        view.layer.cornerRadius = 10
        return view
    }()
    
    // 입장 text1
    private lazy var enterMainLabel: UILabel = {
        let label = UILabel()
        label.text = "초대 코드를 받았다면"
        label.font = UIFont.hcFont(.semiBold, size: 15)
        label.textColor = .gray
        return label
    }()
    
    // 입장 text2
    private lazy var enterSubLabel: UILabel = {
        let label = UILabel()
        label.text = "가족 방 입장하기"
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()
    
    // 입장 text stack
    private lazy var enterLabelStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            enterMainLabel,
            enterSubLabel
        ])
        stack.spacing = 10
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    // 초대 label
    private lazy var hostView: UIView = {
        let view = UIView()
        view.backgroundColor = .Gray500
        view.layer.cornerRadius = 10
        return view
    }()
    
    // 초대 text1
    private lazy var hostMainLabel: UILabel = {
        let label = UILabel()
        label.text = "초대 코드가 없다면"
        label.font = UIFont.hcFont(.semiBold, size: 15)
        label.textColor = .gray
        return label
    }()
    
    // 초대 text2
    private lazy var hostSubLabel: UILabel = {
        let label = UILabel()
        label.text = "가족 방 만들기"
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()
    
    // 초대 text stack
    private lazy var hostLabelStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            hostMainLabel,
            hostSubLabel
        ])
        stack.spacing = 10
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    // 입장초대 viewStack
    private lazy var viewStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            enterView,
            hostView
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
        setupLogoTitle()
        makeUI()
        addGestureRecognizers()
    }
    
    // MARK: - Setup UI
    private func makeUI() {
        // 배경 색상
        view.backgroundColor = .background
        
        // MARK: - logoLabel
//        view.addSubview(logoLabel)
//        logoLabel.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -30),
//            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
        
        // MARK: - mainLabel
        view.addSubview(mainLabel)
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
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
        
        // MARK: - enterLabelStackView -> enterView 위에 올리기
        enterView.addSubview(enterLabelStackView)
        enterLabelStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            enterLabelStackView.centerYAnchor.constraint(equalTo: enterView.centerYAnchor),
            enterLabelStackView.leadingAnchor.constraint(equalTo: enterView.leadingAnchor, constant: 20),
        ])
        
        // MARK: - hostLabelStackView -> hostView 위에 올리기
        hostView.addSubview(hostLabelStackView)
        hostLabelStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostLabelStackView.centerYAnchor.constraint(equalTo: hostView.centerYAnchor),
            hostLabelStackView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor, constant: 20),
        ])
    }
    
    private func addGestureRecognizers() {
        let enterTap = UITapGestureRecognizer(target: self, action: #selector(didTapEnterView))
        enterView.addGestureRecognizer(enterTap)
        enterView.isUserInteractionEnabled = true

        let hostTap = UITapGestureRecognizer(target: self, action: #selector(didTapHostView))
        hostView.addGestureRecognizer(hostTap)
        hostView.isUserInteractionEnabled = true
    }
    
    @objc private func didTapEnterView() {
        print("입장 뷰 터치됨")
        // ex) navigationController?.pushViewController(JoinViewController(), animated: true)
    }

    @objc private func didTapHostView() {
        print("초대 뷰 터치됨")
        // ex) navigationController?.pushViewController(CreateGroupViewController(), animated: true)
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
}

#Preview {
    GroupViewController()
}
