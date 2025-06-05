//
//  RectangleCalendarCell.swift
//  Haruhancut
//
//  Created by 김동현 on 6/5/25.
//

import Foundation
import FSCalendar

final class RectangleCalendarCell: FSCalendarCell {
    
    var isToday: Bool = false
    var isCurrentMonth: Bool = false
    
    private let cellImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let selectedOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    override init!(frame: CGRect) {
        super.init(frame: frame)
        makeUI()
    }

    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeUI() {
        contentView.insertSubview(cellImageView, at: 0)
        contentView.insertSubview(selectedOverlay, aboveSubview: cellImageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 1. cellImageView와 selectedOverlay 똑같이 배치 (정중앙 정사각형)
        let minSide = min(contentView.bounds.width, contentView.bounds.height) - 6
        let frame = CGRect(
            x: (contentView.bounds.width - minSide) / 2,
            y: (contentView.bounds.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        cellImageView.frame = frame
        cellImageView.layer.cornerRadius = minSide / 4
        
        selectedOverlay.frame = frame
        selectedOverlay.layer.cornerRadius = minSide / 4
        
        // 2. 숫자(타이틀) 완전 정중앙!
        let labelSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (contentView.bounds.width - labelSize.width) / 2,
            y: (contentView.bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    
        // 3. 현재월 && 선택시 오버레이만 반투명 하늘색, 아니면 투명
        selectedOverlay.backgroundColor = isSelected && isCurrentMonth
            ? UIColor.hcColor.withAlphaComponent(0.4)
            : .clear

        // titleLabel.font = .hcFont(.bold, size: 15.scaled)
        
        // 4. 오늘 && 현재월이면 테두리 Stroke 추가
        if isToday && isCurrentMonth {
            cellImageView.layer.borderWidth = 3
            cellImageView.layer.borderColor = UIColor.hcColor.cgColor
        } else {
            cellImageView.layer.borderWidth = 0
        }
    }

    /// 기본 이미지 설정 방식
    func setImage(image: UIImage?) {
        self.cellImageView.image = image
    }
    
    /// kingfisher 이미지 설정 방식
    func setImage(url: String) {
        guard let url = URL(string: url) else { return }
        cellImageView.kf.setImage(with: url)
    }
    
    /// 기본 이미지
    func setGrayBox() {
        cellImageView.image = nil
        cellImageView.backgroundColor = .Gray500
    }
    
    /// 기본 이미지
    func setDarkGrayBox() {
        cellImageView.image = nil
        cellImageView.backgroundColor = .Gray700
    }
}
