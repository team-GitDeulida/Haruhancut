////
////  MembersViewController.swift
////  Haruhancut
////
////  Created by 김동현 on 5/27/25.
////
//
//import UIKit
//import RxSwift
//import Kingfisher
//
//final class MembersViewController: UIViewController {
//    
//    weak var coordinator: HomeCoordinator?
//    
//    private let homeViewModel: HomeViewModelType
//    private let memberViewModel: MemberViewModelType
//    
//    private let disposeBag = DisposeBag()
//    
//    init(memberViewModel: MemberViewModelType,
//         homeViewModel: HomeViewModelType
//    ) {
//        self.memberViewModel = memberViewModel
//        self.homeViewModel = homeViewModel
//        
//        // 스토리보드를 쓰지 않고 코드로 UI를 구성시 필수
//        // self의 모든 저장 프로퍼티가 초기화된 이후에만 호출 가능
//        super.init(nibName: nil, bundle: nil)
//        
//        bindMembers()
//    }
//    
//    // 스토리보드를 쓰지 않고 코드로 UI를 구성시 필수
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private lazy var memberScrollView: UIScrollView = {
//        let scroll = UIScrollView()
//        scroll.showsHorizontalScrollIndicator = false
//        return scroll
//    }()
//    
//    private lazy var memberStackView: UIStackView = {
//        let stack = UIStackView()
//        stack.axis = .horizontal
//        stack.spacing = 16
//        stack.alignment = .center
//        return stack
//    }()
//    
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "그룹"
//        label.font = UIFont.hcFont(.bold, size: 20.scaled)
//        label.textColor = .mainWhite
//        return label
//    }()
//    
//    private let textLabel: UILabel = {
//        let label = HCLabel(type: .main(text: "가족 참여 인원"))
//        label.font = .hcFont(.bold, size: 22.scaled)
//        return label
//    }()
//    
//    private lazy var peopleLabel: UILabel = {
//        let label = HCLabel(type: .main(text: "\(0)명"))
//        label.font = .hcFont(.bold, size: 22.scaled)
//        label.textColor = .hcColor
//        return label
//    }()
//    
//    private lazy var titleStack: UIStackView = {
//        let stack = UIStackView(arrangedSubviews: [
//            textLabel,
//            peopleLabel
//        ])
//        stack.axis = .horizontal
//        stack.spacing = 5
//        stack.alignment = .center
//        return stack
//    }()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        makeUI()
//        constraints()
//    }
//    
//    private func makeUI() {
//        view.backgroundColor = .background
//        self.navigationItem.titleView = titleLabel
//        
//        [memberScrollView, titleStack].forEach {
//            view.addSubview($0)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//        
//        memberScrollView.addSubview(memberStackView)
//        memberStackView.translatesAutoresizingMaskIntoConstraints = false
//    }
//    
//    private func constraints() {
//        NSLayoutConstraint.activate([
//            // titleStack
//            titleStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
//            titleStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
//
//            // scrollView
//            memberScrollView.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 20),
//            memberScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            memberScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            memberScrollView.heightAnchor.constraint(equalToConstant: 90),
//
//            // stackView (inside scrollView)
//            memberStackView.topAnchor.constraint(equalTo: memberScrollView.topAnchor),
//            memberStackView.bottomAnchor.constraint(equalTo: memberScrollView.bottomAnchor),
//            memberStackView.leadingAnchor.constraint(equalTo: memberScrollView.leadingAnchor),
//            memberStackView.trailingAnchor.constraint(equalTo: memberScrollView.trailingAnchor),
//            memberStackView.heightAnchor.constraint(equalTo: memberScrollView.heightAnchor)
//        ])
//    }
//    
//    private func bindMembers() {
//        
//        memberViewModel.members
//            .drive(onNext: { [weak self] members in
//                guard let self = self else { return }
//                
//                // 인원 수 라벨 갱신
//                self.peopleLabel.text = "\(members.count)명"
//                
//                // 기본 뷰 제거
//                self.memberStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
//                
//                // 가입순 정렬
//                // let sortedMembers = members.sorted { $0.registerDate < $1.registerDate }
//                
//                // 내 uid가 맨 앞에 오고 + 가입순 정렬
//                let sortedMembers = members.sorted { lhs, rhs in
//                    if lhs.uid == self.homeViewModel.user.value?.uid { return true }
//                    if rhs.uid == self.homeViewModel.user.value?.uid { return false }
//                    return lhs.registerDate < rhs.registerDate
//                }
//                
//                // 멤버마다 동그라미 추가
//                sortedMembers.forEach { user in
//                    
//                    let url = user.profileImageURL.flatMap { URL(string: $0) }
//                    
//                    let circle = FamilyMemberCircleView(
//                        name: user.nickname,
//                        imageURL: url)
//                    
//                    circle.widthAnchor.constraint(equalToConstant: 70).isActive = true
//                    self.memberStackView.addArrangedSubview(circle)
//                    
//                    circle.onProfileTapped = { [weak self] in
//                        guard let self = self else { return }
//                        let previewVC = ImagePreviewViewController(image: circle.image!)
//                        previewVC.modalPresentationStyle = .fullScreen
//                        self.present(previewVC, animated: true)
//                    }
//                }
//            })
//            .disposed(by: disposeBag)
//    }
//}
//
//#Preview {
//    UINavigationController(rootViewController: MembersViewController(memberViewModel: StubMemberViewModel(), homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0])))
//}
//
//
//
//// MARK: - 멤버 동그라미 뷰
//final class FamilyMemberCircleView: UIView {
//    
//    private lazy var imageView: UIImageView = {
//        let imageView = UIImageView()
//        // imageView.contentMode = .scaleAspectFill
//        // imageView.layer.cornerRadius = 30
//        imageView.clipsToBounds = true
//        imageView.tintColor = .gray
//        return imageView
//    }()
//    
//    private lazy var circleView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .Gray300
//        view.clipsToBounds = true
//        return view
//    }()
//    
//    private let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = .hcFont(.bold, size: 14)
//        label.textAlignment = .center
//        label.textColor = .mainWhite
//        return label
//    }()
//    
//    var onProfileTapped: (() -> Void)?
//    
//    var image: UIImage? {
//        return imageView.image
//    }
//    
//    init(name: String, imageURL: URL?) {
//        super.init(frame: .zero)
//        makeUI(name: name)
//        constraints()
//        
//        if let url = imageURL {
//            imageView.contentMode = .scaleAspectFill
//            imageView.kf.setImage(with: url)
//            imageView.transform = .identity // 변형 초기화!
//        } else {
//            
//            imageView.contentMode = .scaleAspectFill
//            imageView.image = UIImage(systemName: "person.fill")
//        }
//        
//        setUpTapGesture()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        circleView.layer.cornerRadius = imageView.frame.width/2
//        imageView.layer.cornerRadius = imageView.frame.width/2
//    }
//    
//    // MARK: - UI Component
//    private func makeUI(name: String) {
//        [circleView, imageView, nameLabel].forEach {
//            addSubview($0)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//        nameLabel.text = name
//    }
//    
//    private func constraints() {
//        NSLayoutConstraint.activate([
//            
//            circleView.topAnchor.constraint(equalTo: topAnchor),
//            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
//            circleView.widthAnchor.constraint(equalToConstant: 60),
//            circleView.heightAnchor.constraint(equalToConstant: 60),
//            
//            imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
//            imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
//            imageView.widthAnchor.constraint(equalTo: circleView.widthAnchor),
//            imageView.heightAnchor.constraint(equalTo: circleView.heightAnchor),
//            
//            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
//            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
//            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
//    }
//    
//    // 버튼 연결
//    private func setUpTapGesture() {
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
//        self.addGestureRecognizer(tapGesture)
//        self.isUserInteractionEnabled = true
//    }
//    
//    // 버튼 누를 시 호출
//    @objc private func profileTapped() {
//        onProfileTapped?()
//    }
//
//}
//
//


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
    private let disposeBag = DisposeBag()
    
    init(memberViewModel: MemberViewModelType,
         homeViewModel: HomeViewModelType) {
        self.memberViewModel = memberViewModel
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
        bindMembers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var memberScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = true
        return scroll
    }()
    
    private lazy var memberStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
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
        let label = HCLabel(type: .main(text: "0명"))
        label.font = .hcFont(.bold, size: 22.scaled)
        label.textColor = .hcColor
        return label
    }()
    
    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [ textLabel, peopleLabel ])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        activateConstraints()
    }
    
    private func makeUI() {
        view.backgroundColor = .background
        navigationItem.titleView = titleLabel
        
        [ titleStack, memberScrollView ].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        memberScrollView.addSubview(memberStackView)
        memberStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func activateConstraints() {
        NSLayoutConstraint.activate([
            // titleStack
            titleStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // scrollView
            memberScrollView.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 20),
            memberScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            memberScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            memberScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // stackView inside scrollView
            memberStackView.topAnchor.constraint(equalTo: memberScrollView.topAnchor),
            memberStackView.bottomAnchor.constraint(equalTo: memberScrollView.bottomAnchor),
            memberStackView.leadingAnchor.constraint(equalTo: memberScrollView.leadingAnchor),
            memberStackView.trailingAnchor.constraint(equalTo: memberScrollView.trailingAnchor),
            
            // prevent horizontal scroll
            memberStackView.widthAnchor.constraint(equalTo: memberScrollView.widthAnchor)
        ])
    }
    
    private func bindMembers() {
        memberViewModel.members
            .drive(onNext: { [weak self] members in
                guard let self = self else { return }
                // 1) 멤버 수 업데이트
                self.peopleLabel.text = "\(members.count)명"
                
                // 2) 기존 서브뷰 제거
                self.memberStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                
                // 3) 최상단에 초대용 버튼 추가
                let addView = AddMemberCircleView()
                addView.heightAnchor.constraint(equalToConstant: 60).isActive = true
                addView.onTap = { [weak self] in
                    guard let self = self else { return }
                    
                    let inviteCode = self.homeViewModel.group.value!.inviteCode
                    self.shareInvitation(inviteCode: inviteCode)
                }
                self.memberStackView.addArrangedSubview(addView)
                
                // 4) 실제 멤버들은 정렬 후 추가
                let sorted = members.sorted { lhs, rhs in
                    if lhs.uid == self.homeViewModel.user.value?.uid { return true }
                    if rhs.uid == self.homeViewModel.user.value?.uid { return false }
                    return lhs.registerDate < rhs.registerDate
                }
                sorted.forEach { user in
                    let url = user.profileImageURL.flatMap(URL.init(string:))
                    let circle = FamilyMemberCircleView(name: user.nickname, imageURL: url)
                    circle.heightAnchor.constraint(equalToConstant: 60).isActive = true
                    circle.onProfileTapped = { [weak self] in
                        guard let self = self, let img = circle.image else { return }
                        let vc = ImagePreviewViewController(image: img)
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: true)
                    }
                    self.memberStackView.addArrangedSubview(circle)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func shareInvitation(inviteCode: String) {
        // 1) 초대 메시지
        let inviteURL = "https://www.notion.so/210db9e736cf80d4b3a8c7e077e6325f?source=copy_link"
        let message = """
우리 가족 그룹에 초대할게요!
초대코드: \(inviteCode)
앱이 궁금하다면 👉 
\(inviteURL)
"""
        // 2) UIActivityViewController 생성
        let items: [Any] = [message]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // 3) iPad 대응(팝오버 위치)
        if let pop = activityVC.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: view.bounds.midX,
                                    y: view.bounds.midY,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        
        // 4) 공유 시트 표시
        present(activityVC, animated: true)
    }
}

// MARK: - 초대용 뷰
final class AddMemberCircleView: UIView {
    // 탭 클릭
    var onTap: (() -> Void)?
    
    private lazy var circleView: UIView = {
        let v = UIView()
        v.backgroundColor = .gray   // 강조색
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        return v
    }()
    private lazy var plusImage: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "plus"))
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private lazy var hStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [ circleView ])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    init() {
        super.init(frame: .zero)
        setup()
        setupConstraints()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        // 원형
        let r = circleView.bounds.width / 2
        circleView.layer.cornerRadius = r
    }
    
    private func setup() {
        addSubview(hStack)
        circleView.addSubview(plusImage)
    }
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 전체 스택
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // circle 크기
            circleView.widthAnchor.constraint(equalToConstant: 60.scaled),
            circleView.heightAnchor.constraint(equalTo: circleView.widthAnchor),
            
            // plusImage 중앙
            plusImage.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            plusImage.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
        ])
    }
    @objc private func didTap() {
        onTap?()
    }
}

// MARK: - FamilyMemberCircleView
final class FamilyMemberCircleView: UIView {
    
    private lazy var circleView: UIView = {
        let v = UIView()
        v.backgroundColor = .Gray300
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .gray
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .hcFont(.bold, size: 14)
        lbl.textColor = .mainWhite
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var hStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [ circleView, nameLabel ])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    var onProfileTapped: (() -> Void)?
    var image: UIImage? { imageView.image }
    
    init(name: String, imageURL: URL?) {
        super.init(frame: .zero)
        nameLabel.text = name
        setupViews()
        setupConstraints()
        loadImage(url: imageURL)
        setUpTapGesture()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 레이아웃이 완료된 후에 radius 설정
        layoutIfNeeded()
        let radius = circleView.bounds.width / 2
        circleView.layer.cornerRadius = radius
        imageView.layer.cornerRadius = radius
    }
    
    private func setupViews() {
        addSubview(hStack)
        circleView.addSubview(imageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // stack 전체를 핀
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // circleView 60×60 고정
            circleView.widthAnchor.constraint(equalToConstant: 60),
            circleView.heightAnchor.constraint(equalTo: circleView.widthAnchor),
            
            // imageView = circleView 크기
            imageView.leadingAnchor.constraint(equalTo: circleView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: circleView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: circleView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: circleView.bottomAnchor),
        ])
    }
    
    private func loadImage(url: URL?) {
        if let url = url {
            imageView.kf.setImage(with: url)
        } else {
            imageView.image = UIImage(systemName: "person.fill")
        }
    }
    
    private func setUpTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    @objc private func profileTapped() { onProfileTapped?() }
}


#Preview {
    UINavigationController(rootViewController: MembersViewController(memberViewModel: StubMemberViewModel(), homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0])))
}

