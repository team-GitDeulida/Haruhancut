//
//  TextViewSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 5/18/25.
//

import UIKit

class CommentTextView: UITextView {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        self.textColor = .mainWhite
        self.tintColor = .mainWhite
        self.backgroundColor = .Gray500
        self.frame = CGRect(x: 0, y: 0, width: 275, height: 0)
        self.layer.cornerRadius = 10
        self.translatesAutoresizingMaskIntoConstraints = false
        self.font = .hcFont(.bold, size: 12)
        // 테스트
        self.textContainerInset = UIEdgeInsets(top: 15, left: 8, bottom: 15, right: 8)
        // print(font?.lineHeight)
    }
}

// MARK: - Priperties

// MARK: - init

// MARK: - Setup UI

// MARK: - Setup Layout

#Preview {
    PostCommentViewController(homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao))), post: .samplePosts[0])
}
