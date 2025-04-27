//  CameraViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import UIKit

final class CameraViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?

    private let viewModel = CameraViewModel()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .mainBlack
    }
}

#Preview {
    CameraViewController()
}
