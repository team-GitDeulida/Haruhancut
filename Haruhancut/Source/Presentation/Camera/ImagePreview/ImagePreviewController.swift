//
//  ImagePreviewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/21/25.
//

import UIKit

// MARK: - 이미지 프리뷰
final class ImagePreviewViewController: UIViewController {
    
    private let image: UIImage
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var imageView: UIImageView = {
        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("닫기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(closePreview), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(imageView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func closePreview() {
        dismiss(animated: true)
    }
}

#Preview {
    ImagePreviewViewController(image: UIImage())
}
