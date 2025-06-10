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
    
    private let homeViewModel: HomeViewModelType
    private let post: Post
    private let disposeBag = DisposeBag()
    private var comments: [(commentId: String, comment: Comment)] = [] // 튜플

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
    
    private lazy var chattingView: ChattingView = {
        let chatView = ChattingView()
        chatView.sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return chatView
    }()
    
    init(homeViewModel: HomeViewModelType, post: Post) {
        self.homeViewModel = homeViewModel
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .Gray700
        
        configureTableView()
        makeUI()
        constraints()
        bindViewModel()
        registerForKeyboardNotifications()
    }
    
    private func configureTableView() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    private func makeUI() {
        
        [headerLabel, tableView, chattingView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: chattingView.topAnchor)
        ])
        
        chatTextViewBottomConstraint = chattingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        chatTextViewBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            chattingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chattingView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        ])
    }
    
    private func bindViewModel() {
        homeViewModel
            .posts
            .asDriver()
            .drive(onNext: { [weak self] posts in
                guard let self = self else { return }
                guard let latestPost = posts.first(where: { $0.postId == self.post.postId }) else { return }

                // 댓글을 최신순 정렬
                let sorted = latestPost.comments
                    .sorted { $0.value.createdAt < $1.value.createdAt }
                    .map { (commentId, comment) -> (String, Comment) in
                        var updatedComment = comment
                        
                        // ✅ 모든 댓글에 대해 userId로 members에서 사용자 찾기
                        if let user = self.homeViewModel.members.value.first(where: { $0.uid == comment.userId }) {
                            updatedComment.profileImageURL = user.profileImageURL
                        }
                        return (commentId: commentId, comment: updatedComment)
                    }
                
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
    
    @objc private func sendButtonTapped() {
        let text = chattingView.text
        guard !text.isEmpty else { return }
        homeViewModel.addComment(post: post, text: text)
        
        // 입력창 초기화
        chattingView.clearInput()
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

extension PostCommentViewController: UITableViewDelegate {
    // 스와이프 액션 처리
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let comment = comments[indexPath.row]
        
        // 본인 댓글이 아닐 경우 삭제 금지
        guard comment.comment.userId == homeViewModel.user.value?.uid else {
            return nil
        }
        
        // 삭제 액션 정의
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            
            // ViewModel 통해 댓글 삭제 요청
            self.homeViewModel.deleteComment(post: self.post, commentId: comment.comment.commentId)
            
            // UI에서 즉시 삭제 (스냅샷 옵저버가 갱신해주기 때문에 생략해도 됨)
            self.comments.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            completionHandler(true)
        }

        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = true // 풀 스와이프 허용 여부
        return config
    }
}

extension UITableViewCell: ReuseIdentifiable {}

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

#Preview {
    let previewPost = Post.samplePosts[1]
    let stubVM = StubHomeViewModel(previewPost: previewPost)
    PostCommentViewController(homeViewModel: stubVM, post: previewPost)
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
