//
//  MembersViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/27/25.
//

import UIKit
import RxSwift
import Kingfisher

final class MembersViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?
    
    private let homeViewModel: HomeViewModelType
    private let memberViewModel: MemberViewModelType
    
    private let disposBag = DisposeBag()
    
    init(memberViewModel: MemberViewModelType,
         homeViewModel: HomeViewModelType
    ) {
        self.memberViewModel = memberViewModel
        self.homeViewModel = homeViewModel
        
        // 스토리보드를 쓰지 않고 코드로 UI를 구성시 필수
        // self의 모든 저장 프로퍼티가 초기화된 이후에만 호출 가능
        super.init(nibName: nil, bundle: nil)
        
        bindMembers()
    }
    
    // 스토리보드를 쓰지 않고 코드로 UI를 구성시 필수
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var memberScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    private lazy var memberStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "그룹"
        label.font = UIFont.hcFont(.bold, size: 20.scaled)
        label.textColor = .mainWhite
        return label
    }()
    
    private let textLabel: UILabel = {
        let label = HCLabel(type: .main(text: "가족 참여 인원"))
        label.font = .hcFont(.bold, size: 22.scaled)
        return label
    }()
    
    private lazy var peopleLabel: UILabel = {
        let label = HCLabel(type: .main(text: "\(0)명"))
        label.font = .hcFont(.bold, size: 22.scaled)
        label.textColor = .hcColor
        return label
    }()
    
    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            textLabel,
            peopleLabel
        ])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
    }
    
    private func makeUI() {
        view.backgroundColor = .background
        self.navigationItem.titleView = titleLabel
        
        [memberScrollView, titleStack].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        memberScrollView.addSubview(memberStackView)
        memberStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            // titleStack
            titleStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            // scrollView
            memberScrollView.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 20),
            memberScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            memberScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            memberScrollView.heightAnchor.constraint(equalToConstant: 90),

            // stackView (inside scrollView)
            memberStackView.topAnchor.constraint(equalTo: memberScrollView.topAnchor),
            memberStackView.bottomAnchor.constraint(equalTo: memberScrollView.bottomAnchor),
            memberStackView.leadingAnchor.constraint(equalTo: memberScrollView.leadingAnchor),
            memberStackView.trailingAnchor.constraint(equalTo: memberScrollView.trailingAnchor),
            memberStackView.heightAnchor.constraint(equalTo: memberScrollView.heightAnchor)
        ])
    }
    
    private func bindMembers() {
        memberViewModel.members
            .drive(onNext: { [weak self] members in
                guard let self = self else { return }
                
                // 인원 수 라벨 갱신
                self.peopleLabel.text = "\(members.count)명"
                
                // 기본 뷰 제거
                self.memberStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                
                // 가입순 정렬
                // let sortedMembers = members.sorted { $0.registerDate < $1.registerDate }
                
                // 내 uid가 맨 앞에 오고 + 가입순 정렬
                let sortedMembers = members.sorted { lhs, rhs in
                    if lhs.uid == self.homeViewModel.user.value?.uid { return true }
                    if rhs.uid == self.homeViewModel.user.value?.uid { return false }
                    return lhs.registerDate < rhs.registerDate
                }
                
                // 멤버마다 동그라미 추가
                sortedMembers.forEach { user in
                    
                    let url = user.profileImageURL.flatMap { URL(string: $0) }
                    
                    let circle = FamilyMemberCircleView(
                        name: user.nickname,
                        imageURL: url)
                    
                    circle.widthAnchor.constraint(equalToConstant: 70).isActive = true
                    self.memberStackView.addArrangedSubview(circle)
                    
                    circle.onProfileTapped = { [weak self] in
                        guard let self = self else { return }
                        let previewVC = ImagePreviewViewController(image: circle.image!)
                        previewVC.modalPresentationStyle = .fullScreen
                        self.present(previewVC, animated: true)
                    }
                }
            })
            .disposed(by: disposBag)
    }
}

#Preview {
    UINavigationController(rootViewController: MembersViewController(
        memberViewModel: StubMemberViewModel(groupRelay: .init(value: .sampleGroup), membersRelay: .init(value: [User.empty(loginPlatform: .kakao)])),
        homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0])))
}


// MARK: - 멤버 동그라미 뷰
final class FamilyMemberCircleView: UIView {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.tintColor = .gray
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .hcFont(.bold, size: 14)
        label.textAlignment = .center
        label.textColor = .mainWhite
        return label
    }()
    
    var onProfileTapped: (() -> Void)?
    
    var image: UIImage? {
        return imageView.image
    }
    
    init(name: String, imageURL: URL?) {
        super.init(frame: .zero)
        makeUI(name: name)
        constraints()
        
        if let url = imageURL {
            imageView.kf.setImage(with: url)
        } else {
            imageView.image = UIImage(systemName: "person.fill")
        }
        
        setUpTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Component
    private func makeUI(name: String) {
        [imageView, nameLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        nameLabel.text = name
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // 버튼 연결
    private func setUpTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    // 버튼 누를 시 호출
    @objc private func profileTapped() {
        onProfileTapped?()
    }

}


