//  GroupDetailViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/25/25.
//

import UIKit

final class GroupDetailViewController: UIViewController {

    weak var coordinator: HomeCoordinator?
    
    private let viewModel = GroupDetailViewModel()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
    }
}

#Preview {
    GroupDetailViewController()
}
