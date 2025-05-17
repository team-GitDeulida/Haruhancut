//
//  CommentCell.swift
//  Haruhancut
//
//  Created by 김동현 on 5/17/25.
//

import UIKit

final class CommentCell: UITableViewCell {
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        iv.image = UIImage(systemName: "person", withConfiguration: config)?.withRenderingMode(.alwaysTemplate)

        iv.contentMode = .center
        iv.tintColor = .mainWhite
        iv.backgroundColor = .gray.withAlphaComponent(0.3)
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20

        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 40),
            iv.heightAnchor.constraint(equalToConstant: 40)
        ])

        return iv
    }()
    
    private lazy var vStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nicknameLabel, contentLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [profileImageView, vStack])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var nicknameLabel: HCLabel = {
        let label = HCLabel(type: .commentAuther(text: "닉네임1"))
        return label
    }()
    
    private lazy var contentLabel: HCLabel = {
        let label = HCLabel(type: .commentContent(text: "테스트 댓글"))
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier) /// 부모의 로직을 싱행시키는 의미
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        self.backgroundColor = .clear
        
        contentView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(comment: Comment) {
        nicknameLabel.text = comment.nickname
        contentLabel.text = comment.text
    }
}

#if DEBUG
import SwiftUI

extension UIView {
    private struct ViewRepresentable: UIViewRepresentable {
        let uiView: UIView
        func updateUIView(_ uiView: UIViewType, context: Context) {
        }
        func makeUIView(context: Context) -> some UIView {
            uiView
        }
    }
    
    func getPreview() -> some View {
        ViewRepresentable(uiView: self)
    }
}
#endif

#if DEBUG
import SwiftUI

struct CommentCell_PreviewProvider_Previews: PreviewProvider {
    static var previews: some View {
        CommentCell().getPreview()
            .previewLayout(.fixed(width: 200, height: 100))
    }
}
#endif
