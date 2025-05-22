//
//  ImagePreviewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/21/25.
//

import UIKit

// MARK: - 이미지 프리뷰
final class ImagePreviewViewController: UIViewController, UIScrollViewDelegate {
    
    private let image: UIImage
    
    // zoom in/out을 위한 스크롤뷰 추가
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 3.0
        sv.delegate = self
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

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
    
    private lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("저장", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(savePreview), for: .touchUpInside)
        return btn
    }()
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeButton)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            // scrollView가 전체 화면을 덮도록
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // imageView는 scrollView크기와 동일
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            

            // 닫기 버튼
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 저장 버튼
            saveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
            
        ])
    }

    @objc private func closePreview() {
        dismiss(animated: true)
    }
    
    @objc private func savePreview() {
        // 앨범에 사진 저장
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // 저장 알림 표시
        let alert = UIAlertController(title: "사진 저장",
                                      message: "사진이 앨범에 저장되었습니다.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // 줌 대상 지정
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

#Preview {
    ImagePreviewViewController(image: UIImage())
}
