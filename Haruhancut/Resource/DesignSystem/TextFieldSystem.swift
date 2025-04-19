//
//  TextFieldSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 4/19/25.
//

import UIKit

final class HCTextField: UITextField {
    
    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.textColor = .mainWhite
        self.tintColor = .mainWhite
        self.backgroundColor = .Gray500
        self.layer.cornerRadius = DynamicSize.scaledSize(10)
        self.addLeftPadding()
        self.setPlaceholderColor(color: .Gray200)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - Priperties

// MARK: - init

// MARK: - Setup UI

// MARK: - Setup Layout
