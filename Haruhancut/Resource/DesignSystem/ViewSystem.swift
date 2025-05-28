//
//  ViewSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 5/26/25.
//

import UIKit
import Kingfisher

final class BubbleView: UIView {
    
    private let cornerRadius: CGFloat = 20
    private let tipWidth: CGFloat = 20
    private let tipHeight: CGFloat = 10
    private lazy var textLabel: HCLabel = {
        let label = HCLabel(type: .custom(text: text,
                                          font: .hcFont(.bold, size: 16),
                                          color: .mainWhite))
        label.textAlignment = .center
        return label
    }()
    
    var text: String {
        didSet {
            textLabel.text = text
            setNeedsDisplay() // 말풍선 다시 그리기 (tip 중앙 유지용)
        }
    }
    
    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        self.backgroundColor = .clear
        makeUI()
        constraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 말풍선 모양
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height - tipHeight // 말풍선 높이
        
        // 시작저미 왼쪽 위 모서리
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // 상단 라인
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: width, y: cornerRadius),
                          controlPoint: CGPoint(x: width, y: 0))
        
        // 우측 라인
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: width - cornerRadius, y: height),
                          controlPoint: CGPoint(x: width, y: height))
        
        // 아래쪽 중앙에 tip 삼각형 추가
        let tipStartX = (width - tipWidth) / 2
        path.addLine(to: CGPoint(x: tipStartX + tipWidth, y: height))
        path.addLine(to: CGPoint(x: width / 2, y: height + tipHeight))
        path.addLine(to: CGPoint(x: tipStartX, y: height))

        // 좌측 라인
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - cornerRadius),
                          controlPoint: CGPoint(x: 0, y: height))

        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0),
                          controlPoint: CGPoint(x: 0, y: 0))
        
        // ✅ 색상 채우기
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.Gray500.cgColor

        layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
        layer.insertSublayer(shapeLayer, at: 0)
    }
    
    private func makeUI() {
        addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -tipHeight - 12),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}

// MARK: - 프로필 이미지 뷰 (카메라 버튼 + 원형 이미지 탭 가능)
final class ProfileImageView: UIView {

    // MARK: - UI Component
    // 프로필 이미지 표시용 이미지 뷰
    private let imageView = UIImageView()
    
    // 카메라 버튼(이미지 우측 하단)
    private let cameraButton = UIButton(type: .system)

    // MARK: - Constraints
    // 초기 아이콘 크기 제약(작은 아이콘 형태)
    private var iconSizeConstraints: [NSLayoutConstraint] = []
    // 이미지가 전체를 채울 때 사용하는 제약
    private var fullSizeConstraints: [NSLayoutConstraint] = []

    // MARK: - 외부 콜백
    // 카메라 버튼 탭 시 호출
    var onCameraTapped: (() -> Void)?
    // 원형 전체 영역 탭 시 호출
    var onProfileTapped: (() -> Void)?

    init(size: CGFloat = 100, iconSize: CGFloat = 50) {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .Gray500
        layer.cornerRadius = size / 2
        clipsToBounds = false   // 이미지뷰만 원형으로 잘리도록

        setupImageView(iconSize: iconSize)
        setupCameraButton()     // 카메라 탭 제스처 추가
        setUpTapGesture()       // 큰 원 영역 탭 제스처 추가

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalTo: widthAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = bounds.width / 2
    }

    // 프로필 아이콘 이미지 뷰 설정
    private func setupImageView(iconSize: CGFloat) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "person.fill")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit

        addSubview(imageView)

        iconSizeConstraints = [
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: iconSize),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ]
        NSLayoutConstraint.activate(iconSizeConstraints)
    }

    // 카메라 버튼 설정
    private func setupCameraButton() {
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let cameraImage = UIImage(systemName: "camera.circle.fill", withConfiguration: config)
        cameraButton.setImage(cameraImage, for: .normal)
        cameraButton.tintColor = .white
        cameraButton.backgroundColor = .mainBlack
        cameraButton.layer.cornerRadius = 16
        cameraButton.clipsToBounds = true

        addSubview(cameraButton)
        NSLayoutConstraint.activate([
            cameraButton.widthAnchor.constraint(equalToConstant: 32),
            cameraButton.heightAnchor.constraint(equalTo: cameraButton.widthAnchor),
            cameraButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 6),
            cameraButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 6)
        ])

        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
    }
    
    // 카메라 버튼 탭 시 호출
    @objc private func cameraTapped() {
        onCameraTapped?()
    }
    
    // 프로필 전체 원형 뷰에 버튼 설정
    private func setUpTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    // 프로필 원형 전체 탭 시 호출
    @objc private func profileTapped() {
        onProfileTapped?()
    }
}

extension ProfileImageView {
    
    // MARK: - 유저가 사진 선택 후 바로 반영
    func setImage(_ image: UIImage) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        // 기존 작은 제약 해제
        NSLayoutConstraint.deactivate(iconSizeConstraints)

        // 전체 꽉 채우는 제약 적용 (한 번만 생성)
        if fullSizeConstraints.isEmpty {
            fullSizeConstraints = [
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        }
        NSLayoutConstraint.activate(fullSizeConstraints)
    }
    
    // MARK: - 서버에서 URL 갱신되면, 비동기 로딩
    func setImage(with url: URL) {
        imageView.kf.setImage(
            with: url,
            placeholder: imageView.image // ✅ 현재 이미지 유지
            //placeholder: UIImage(systemName: "person.fill")
            
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.imageView.contentMode = .scaleAspectFill
                self.imageView.clipsToBounds = true
                NSLayoutConstraint.deactivate(self.iconSizeConstraints)

                if self.fullSizeConstraints.isEmpty {
                    self.fullSizeConstraints = [
                        self.imageView.topAnchor.constraint(equalTo: self.topAnchor),
                        self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                        self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                        self.imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
                    ]
                }
                NSLayoutConstraint.activate(self.fullSizeConstraints)
            case .failure(let error):
                print("❌ 이미지 로딩 실패: \(error.localizedDescription)")
            }
        }
    }
}

extension ProfileImageView {
    var image: UIImage? {
        return imageView.image
    }
}


#Preview {
    HomeViewController(
        loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()),
        homeViewModel: HomeViewModel(loginUsecase: StubLoginUsecase(), groupUsecase: StubGroupUsecase(), userRelay: .init(value: User.empty(loginPlatform: .kakao))))
}
