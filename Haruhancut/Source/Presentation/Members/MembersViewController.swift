//
//  MembersViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/27/25.
//

import UIKit

final class MembersViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    let group: HCGroup
    
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
        self.group = homeViewModel.group.value!
        
        // 스토리보드를 쓰지 않고 코드로 UI를 구성시 필수
        // self의 모든 저장 프로퍼티가 초기화된 이후에만 호출 가능
        super.init(nibName: nil, bundle: nil)
    }
    
    // 스토리보드를 쓰지 않고 코드로 UI를 구성시 필수
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    private lazy var peopleLavel: UILabel = {
        let label = HCLabel(type: .main(text: "\(self.group.members.count)명"))
        label.font = .hcFont(.bold, size: 22.scaled)
        label.textColor = .hcColor
        return label
    }()
    
    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            textLabel,
            peopleLavel
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
        
        [titleStack].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            titleStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
//            textLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
//            textLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
//            
//            peopleLavel.topAnchor.constraint(equalTo: textLabel.topAnchor),
//            peopleLavel.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 5)
        ])
    }
}

#Preview {
    UINavigationController(rootViewController: MembersViewController(homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0])))
}
