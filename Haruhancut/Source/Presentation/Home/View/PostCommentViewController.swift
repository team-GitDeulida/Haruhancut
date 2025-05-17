//
//  PostCommentViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/17/25.
//

import UIKit
import RxSwift

final class PostCommentViewController: UIViewController {
    
    // 키보드 가림 해결을 위한 bottom constraint속성
    private var chatTextViewBottomConstraint: NSLayoutConstraint?
    
    private let homeViewModel: HomeViewModel
    private let post: Post
    private let disposeBag = DisposeBag()
    private var comments: [(commentId: String, comment: Comment)] = []

    // MARK: - UI Component
    
    private let headerLabel: UILabel = {
        let label = HCLabel(type: .custom(text: "댓글", font: .hcFont(.bold, size: 16), color: .mainWhite))
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    private lazy var chatTextView: CommentTextView = {
        let textView = CommentTextView()
        textView.isScrollEnabled = false // 초기 스크롤 불가능(4줄 이상부터 가능)
        return textView
    }()
    
    init(homeViewModel: HomeViewModel, post: Post) {
        self.homeViewModel = homeViewModel
        self.post = post
        super.init(nibName: nil, bundle: nil)
        print(post)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .Gray700
        
        configureTableView()
        configureUI()
        bindViewModel()
        
        chatTextView.delegate = self
        registerForKeyboardNotifications()
    }
    
    private func configureTableView() {
        self.tableView.dataSource = self
    }
    
    private func configureUI() {
        
        // MARK: - 테이블뷰 관련
        [headerLabel, tableView, chatTextView].forEach {
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: chatTextView.topAnchor)
        ])
        
        let test = (chatTextView.font?.lineHeight ?? 16) + chatTextView.textContainerInset.top + chatTextView.textContainerInset.bottom
        
        chatTextViewBottomConstraint = chatTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        chatTextViewBottomConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            // 위치
            // chatTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            chatTextView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 크기
            chatTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            chatTextView.heightAnchor.constraint(equalToConstant: test)
            // chatTextView.heightAnchor.constraint(equalToConstant: 31.6)
        ])
    }
    
    private func bindViewModel() {
        homeViewModel
            .posts
            .asDriver()
            .drive(onNext: { [weak self] posts in
                guard let self = self else { return }
                guard let latestPost = posts.first(where: { $0.postId == self.post.postId }) else { return }

                let sorted = latestPost.comments
                    .sorted { $0.value.createdAt < $1.value.createdAt }
                    .map { (commentId: $0.key, comment: $0.value) }
                
                self.comments = sorted // [(key, Comment)]
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)

    }
    
    /// 화면에 보여지기 직전에 호출되는 생명주기 메서드
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// pageSheet일때만
        if let sheet = self.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let fiftyPercentDetent = UISheetPresentationController.Detent.custom(identifier: .init("fiftyPercent")) { context in
                                return context.maximumDetentValue * 0.6
                            }

                let eightyPercentDetent = UISheetPresentationController.Detent.custom(identifier: .init("eightyPercent")) { context in
                    return context.maximumDetentValue * 0.9
                }
                
                sheet.detents = [fiftyPercentDetent, eightyPercentDetent]
            } else {
                sheet.detents = [.medium(), .large()]
            }
            /// 바텀시트 상단에 손잡이(Grabber) 표시 여부
            sheet.prefersGrabberVisible = true
            /// 시트의 상단 모서리를 30pt 둥글게
            sheet.preferredCornerRadius = 30
        }
        
        modalPresentationStyle = .pageSheet
    }
}

extension PostCommentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseIdentifier, for: indexPath) as? CommentCell else {
            return UITableViewCell()
        }
        
        let comment = comments[indexPath.row].comment
        cell.configure(comment: comment)
        
        // 선택 효과 제거(터치는 가능하지만 시각적 변화 X)
        cell.selectionStyle = .none
        return cell
    }
}

protocol ReuseIdentifiable {
    // 프로토콜에서 로직을 정의할 수 없어서 가져올 수 있도록 설정
    static var reuseIdentifier: String { get }
}

extension ReuseIdentifiable {
    // 로직에 대한 정의는 Extension에서 간능
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

extension UITableViewCell: ReuseIdentifiable {}

#Preview {
    PostCommentViewController(homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao))), post: .samplePosts[0])
}

extension PostCommentViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: view.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        // estimatedSize
        // 1줄일 때 31.6
        // 2줄일 때 47.3
        // 3줄일 때 62.6
        
        if estimatedSize.height > 65 {
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

// MARK: - 키보드 알림
extension PostCommentViewController {
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let bottomInset = keyboardFrame.height - view.safeAreaInsets.bottom
        chatTextViewBottomConstraint?.constant = -bottomInset - 10
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        chatTextViewBottomConstraint?.constant = -10
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
