//
//  PostCell.swift
//  Haruhancut
//
//  Created by 김동현 on 5/3/25.
//

import UIKit
import Kingfisher

final class PostCell: UICollectionViewCell {
    static let identifier = "PostCell"
    
    // 이미지 뷰: 셀의 배경 이미지를 보여줌
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill           // 셀 채우되 비율 유지
        iv.clipsToBounds = true                     // 셀 밖 이미지 자르기
        iv.layer.cornerRadius = 15                  // 모서리 둥글게
        return iv
    }()
    
    // 타이틀 라벨: 이미지 위에 카드 이름 보여줌
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.3) // 반투명 배경
        label.textColor = .white
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    // 셀 생성자: 이미지 뷰와 라벨을 셀에 추가
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        imageView.addSubview(titleLabel)
        
        contentView.addSubview(titleLabel)
        imageView.frame = contentView.bounds
        titleLabel.frame = CGRect(x: 0,
                                  y: contentView.bounds.height - 30, // 아래쪽에 고정
                                  width: contentView.bounds.width,
                                  height: 30)
        
        
//        contentView.addSubview(titleLabel)
//        titleLabel.frame = contentView.bounds
//        titleLabel.textAlignment = .center
//        titleLabel.textColor = .mainWhite
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 외부에서 데이터를 받아 셀 구성
    func configure(with post: Post) {
        titleLabel.text = post.nickname
        
        let url = URL(string: post.imageURL)
        imageView.kf.setImage(with: url)
    }
}
