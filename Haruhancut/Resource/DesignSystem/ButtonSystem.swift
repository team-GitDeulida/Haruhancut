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
        config.imagePadding = 20.scaled
        config.title = title
        config.baseBackgroundColor = .black
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.hcFont(.semiBold, size: 16)
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
        self.layer.cornerRadius = 20
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

/// 다음 버튼
final class HCNextButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        self.configure(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(title: String) {
        var config = UIButton.Configuration.filled()
        config.title = "완료"
        config.baseForegroundColor = .mainBlack
        config.baseBackgroundColor = .mainWhite
        
        self.configuration = config
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        self.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.baseBackgroundColor = button.isHighlighted ? .lightGray : .mainWhite
            button.configuration = updated
        }
    }
}

/// 그룹 버튼
final class HCGroupButton: UIButton {
    
    init(topText: String, bottomText: String, rightImage: String) {
        super.init(frame: .zero)
        self.mainLabel.text = topText
        self.subLabel.text = bottomText
        rightImageView.image = UIImage(systemName: rightImage)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.hcFont(.semiBold, size: 15)
        label.textColor = .gray
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var subLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        label.backgroundColor = .clear
        return label
    }()
    
    /// 바로 초기화
    private let rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        // 이미지 비율을 유지한 채, View 영역 안에 맞춤
        imageView.contentMode = .scaleAspectFit
        /*
         가로 방향에서 자신이 최대한 줄어들고 싶다고 우선순위를 줌
         [UILabel][UIImageView]  ← 이런 구조일 때
         label은 최대한 넓게, imageView는 아이콘만큼만 표시됨
        */
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var labelStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel,
        ])
        stack.spacing = 10
        stack.axis = .vertical
        stack.isUserInteractionEnabled = false
        stack.backgroundColor = .clear
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var hStack: UIStackView = {
        let hstack = UIStackView(arrangedSubviews: [labelStackView, UIView(), rightImageView])
        hstack.axis = .horizontal
        hstack.spacing = 10
        hstack.alignment = .center
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.isUserInteractionEnabled = false // ✅ 터치 이벤트 가로채지 않도록
        return hstack
    }()
    
    private func configure() {
        var config = UIButton.Configuration.plain()
        config.baseBackgroundColor = .Gray500
        config.background.backgroundColor = .Gray500
        
        self.configuration = config
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        self.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.baseBackgroundColor = button.isHighlighted ? .black : .Gray500
            config?.background.backgroundColor = button.isHighlighted ? .Gray700 : .Gray500
            button.configuration = config
        }

        
        self.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            hStack.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}

/// 댓글 버튼
final class HCCommentButton: UIButton {
    
    private let leftImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        // 나는 최대한 작고 싶어 라는 우선순위 설정
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.hcFont(.semiBold, size: 15)
        label.textColor = .mainWhite
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var hStack: UIStackView = {
        let hstack = UIStackView(arrangedSubviews: [leftImageView, countLabel])
        hstack.axis = .horizontal
        hstack.spacing = 10
        hstack.alignment = .center
        hstack.isUserInteractionEnabled = false
        hstack.translatesAutoresizingMaskIntoConstraints = false
        return hstack
    }()
    
    init(image: UIImage, count: Int) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leftImageView.image = image
        self.countLabel.text = String(count)
        makeUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCount(_ count: Int) {
        countLabel.text = "\(count)"
    }
    
    private func makeUI() {
        self.backgroundColor = .darkGray
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
    }
    
    private func setupConstraints() {
        self.addSubview(hStack)
        NSLayoutConstraint.activate([

            // 위치
            hStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            hStack.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            // 크기
            hStack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        ])
    }
}

/// 업로드 버튼
final class HCUploadButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        self.configure(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(title: String) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = .mainBlack
        config.baseBackgroundColor = .mainWhite
        
        self.configuration = config
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        self.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.baseBackgroundColor = button.isHighlighted ? .lightGray : .mainWhite
            button.configuration = updated
        }
    }
}


#Preview {
    PostDetailViewController(homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao))), post: .samplePosts[0])
}

#Preview {
    HCUploadButton(title: "완료1")
}

/*
 [그룹 버튼]
    private lazy var enterButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseBackgroundColor = .Gray500
        config.background.backgroundColor = .Gray500

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 10
        button.clipsToBounds = true

        button.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.baseBackgroundColor = button.isHighlighted ? .black : .Gray500
            config?.background.backgroundColor = button.isHighlighted ? .Gray700 : .Gray500
            button.configuration = config
        }
        button.addTarget(self, action: #selector(test), for: .touchUpInside)

        return button
    }()
*/
