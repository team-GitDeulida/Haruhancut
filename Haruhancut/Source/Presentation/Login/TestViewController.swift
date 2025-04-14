//
//  TestViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/14/25.
//
/*
 https://so-kyte.tistory.com/119
 */

import UIKit

class TestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
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
        textfield.backgroundColor = .green
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
        let button = UIButton()
        button.setTitle("다음", for: .normal)
        return button
    }()
    
    func makeUI() {
        view.backgroundColor = .background
        
        // MARK: - labelStack
        // 1. view에 버튼 추가
        view.addSubview(labelStackView)
        
        // 2. 오토레이아웃 활성화
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. 오토레이아웃 제약 추가
        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),        // y축 위치
            labelStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20) // x축 위치
        ])
        
        // MARK: - textField
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: labelStackView.bottomAnchor, constant: 50),        // y축 위치
            textField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        
        
    }
    
    @objc private func didTapNext() {
        self.navigationController?.setViewControllers([
            HomeViewController()
        ], animated: true)
    }
}

#Preview {
    TestViewController()
}
