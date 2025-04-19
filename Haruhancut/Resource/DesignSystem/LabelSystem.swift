//
//  LabelSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 4/19/25.
//

import UIKit

/*
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
 */

final class HCLabel: UILabel {
    
    enum LabelType {
        case main(text: String)
        case sub(text: String)
    }
    
    init(type: LabelType) {
        super.init(frame: .zero)
        configure(type: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(type: LabelType) {
        numberOfLines = 0
        
        switch type {
        case .main(let text):
            textColor = .mainWhite
            font = UIFont.hcFont(.bold, size: 20)
            self.text = text
        case .sub(let text):
            textColor = .gray
            font = UIFont.hcFont(.semiBold, size: 15)
            self.text = text
        }
    }
}
