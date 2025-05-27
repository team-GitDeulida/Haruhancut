//
//  ChattingViewSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 5/20/25.
//

import UIKit

// MARK: - CustomView Template
class BaseView: UIView {
    
    // 코드로 초기화할 때 실행되는 생성자
    override init(frame: CGRect) {
        super.init(frame: frame)
        makeUI()
        constraints()
    }
    
    // 스토리보드/XIB 사용 금지
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // UI 구성용 함수 (서브클래스에서 override 가능)
    func makeUI() {
        
    }
    
    // 제약조건 설정용 함수 (서브클래스에서 override 가능)/
    func constraints() {
        
    }
}

// MARK: - 텍스트뷰
final class ChattingTextView: UITextView {
    
    /// placeholder label
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "메시지를 입력하세요"
        label.textColor = .placeholderText
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()
    
    /// 지정된 텍스트 컨테이너로 새 텍스트 보기를 만든다
    /// - Parameters:
    ///   - frame: 텍스트 보기의 프레임 사각형
    ///   - textContainer: 수신자에 사용할 텍스트 컨테이너
    ///   - return: 초기화된 텍스트 보기
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        makeUI()
        constraints()
    }
    
    /// 스토리보드 금지용 안전장치
    /// 코드베이스로 작성시 혹시라도 누군가가 실수로 스토리보드에서 이 클래스를 사용하면 앱이 죽게(fatalError)해서 알려주기 위한 장치
    /// 서브 클래스에서 모든 프로퍼티가 기본 값을 가지고 있어서 지정 생성자를 따로 작성하지 않으면 부모 클래스의 지정 생성자를 모두 상속받는다
    /// 지정 생성자를 직접 서브클래스에서 작성한다면 required init()이 필수적이다
    /// - Parameter coder: storyboard나 xib로 구현한 UI는 xml 형태로 저장하는데, 이 xml형태를 화면으로 가져올 때 사용되는 것
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeUI() {
        /// 기본 스타일
        font = .systemFont(ofSize: 16)
        
        /// 모서리 둥글게 설정
        layer.cornerRadius = 12
        clipsToBounds = true
        
        /// 배경 제거
        backgroundColor = .clear
        
        /// 테두리 색상
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor /// cgColor: UIColor -> CoreGraphics에서 사용 가능한 색상 객체
        
        // ✅ 커서가 너무 위로 붙는 문제 해결
        textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        /// 텍스트가 입력되면 placeholder 숨기기
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }
    
    private func constraints() {
        addSubview(placeholderLabel)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 위치
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
        ])
    }
    
    /// 텍스트 변경시 placeholder 숨김
    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
}

// MARK: - 텍스트뷰 + 버튼뷰
final class ChattingView: BaseView {
    // 동적 높이
    private var heightConstraint: NSLayoutConstraint?
    
    // 텍스트뷰
    private let chattingTextView: ChattingTextView = {
        let view = ChattingTextView()
        view.isScrollEnabled = false
        return view
    }()
    
    // 버튼
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("전송", for: .normal)
        button.setTitleColor(.mainBlack, for: .normal)
        button.backgroundColor = .hcColor
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [chattingTextView, sendButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .bottom
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func makeUI() {
        chattingTextView.delegate = self
        addSubview(hStack)
    }
    
    override func constraints() {
        
        // 높이 초기값
        let initialHeight = (chattingTextView.font?.lineHeight ?? 16)
              + chattingTextView.textContainerInset.top
              + chattingTextView.textContainerInset.bottom

        // 동적높이 = 텍스트뷰높이 = 초기값
        heightConstraint = chattingTextView.heightAnchor.constraint(equalToConstant: initialHeight)
        heightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            // sendButton 고정 크기(가로: 고정, 세로: 텍스트뷰 높이 초기값)
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            sendButton.heightAnchor.constraint(equalToConstant: initialHeight),
        ])
    }
}

// 댓글 전송 관련
extension ChattingView {
    var text: String {
        return chattingTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    func clearInput() {
        chattingTextView.text = ""
        chattingTextView.delegate?.textViewDidChange?(chattingTextView)
    }
//    /// 입력창의 폰트 높이 + 위아래 패딩을 합산한 예상 높이
//    var estimatedHeight: CGFloat {
//        (chattingTextView.font?.lineHeight ?? 16)
//        + chattingTextView.textContainerInset.top
//        + chattingTextView.textContainerInset.bottom
//    }
}

// 높이 변화 관련
extension ChattingView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: self.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        // estimatedSize
        // 1줄일 때 31.6
        // 2줄일 때 47.3
        // 3줄일 때 62.6
        
        if estimatedSize.height > 130 {
            textView.isScrollEnabled = true
            return
        } else {
            textView.isScrollEnabled = false

            // 레이아웃 중 height 수정
            textView.constraints.forEach { constraint in
                if constraint.firstAttribute == .height {
                    constraint.constant = estimatedSize.height
                }
            }
        }
    }
}
