//
//  ButtonSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 4/19/25.
//

import UIKit

/// 소셜 로그인 버튼
final class SocialLoginButton: UIButton {
    enum LoginType {
        case kakao, apple
    }
    
    init(type: LoginType, title: String) {
        super.init(frame: .zero)
        self.configure(type: type, title: title)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(type: LoginType, title: String) {
        var config = UIButton.Configuration.filled()
        config.imagePlacement = .leading
        config.imagePadding = DynamicSize.scaledSize(20)
        config.title = title
        config.baseBackgroundColor = .black
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.hcFont(.semiBold, size: DynamicSize.scaledSize(16))
            return outgoing
        }
        
        switch type {
        case .kakao:
            config.image = UIImage(named: "Logo Kakao")
            config.baseForegroundColor = .mainBlack
        case .apple:
            config.image = UIImage(named: "Logo Apple")
            config.baseForegroundColor = .mainBlack
        }
        
        self.configuration = config
        self.layer.cornerRadius = DynamicSize.scaledSize(10)
        self.clipsToBounds = true
        
        /// 눌렀을 때 생상 변경
        self.configurationUpdateHandler = { button in
            var config = button.configuration
            switch type {
            case .kakao:
                config?.baseBackgroundColor = button.isHighlighted ? .kakaoTapped : .kakao
            case .apple:
                config?.baseBackgroundColor = button.isHighlighted ? .appleTapped : .apple
            }
            button.configuration = config
        }
    }
}
