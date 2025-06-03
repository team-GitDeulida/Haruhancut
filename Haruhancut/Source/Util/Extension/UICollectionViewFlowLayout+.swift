//
//  UICollectionViewFlowLayout+.swift
//  Haruhancut
//
//  Created by 김동현 on 6/2/25.
//

import UIKit

extension UICollectionViewFlowLayout {
    /// 컬렉션 뷰 셀 크기를 자동으로 계산해주는 함수
    /// - Parameters:
    ///   - columns: 한 행에 보여줄 셀 개수
    ///   - spacing: 셀 사이 간격 (기본값 16)
    ///   - inset: 좌우 마진 (기본값 16)
    /// - Returns: 계산된 셀 크기
    func calculateItemSize(columns: Int, spacing: CGFloat = 16, inset: CGFloat = 16) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let totalSpacing = spacing * CGFloat(columns - 1) + inset * 2
        let itemWidth = (screenWidth - totalSpacing) / CGFloat(columns)
        
        let imageHeight = itemWidth
        let labelHeight: CGFloat = 20 + 14 + 8 // nickname + spacing + bottom margin
        return CGSize(width: itemWidth, height: imageHeight + labelHeight) // 정사각형 셀
    }
}
