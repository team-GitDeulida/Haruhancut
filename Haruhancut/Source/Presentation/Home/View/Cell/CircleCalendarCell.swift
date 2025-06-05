//
//  CircleCalendarCell.swift
//  Haruhancut
//
//  Created by 김동현 on 6/5/25.
//

import Foundation
import FSCalendar

final class CircleCalendarCell: FSCalendarCell {
    let backImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    // 선택 시 반투명 빨간색 오버레이
    let selectedOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.insertSubview(backImageView, at: 0)
        contentView.insertSubview(selectedOverlay, aboveSubview: backImageView)
    }
    
    required init(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let minSide = min(contentView.bounds.width, contentView.bounds.height) - 6
        let frame = CGRect(
            x: (contentView.bounds.width - minSide) / 2,
            y: (contentView.bounds.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        backImageView.frame = frame
        backImageView.layer.cornerRadius = minSide / 2
        
        // 오버레이도 동일한 프레임과 둥글기
        selectedOverlay.frame = frame
        selectedOverlay.layer.cornerRadius = minSide / 2
        
        let labelSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (contentView.bounds.width - labelSize.width) / 2,
            y: (contentView.bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        
        // 선택시 오버레이만 반투명 빨간색, 아니면 투명
        selectedOverlay.backgroundColor = isSelected
            ? UIColor.red.withAlphaComponent(0.4) // ← 적당히 조절
            : .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backImageView.image = nil
        selectedOverlay.backgroundColor = .clear
    }
}
