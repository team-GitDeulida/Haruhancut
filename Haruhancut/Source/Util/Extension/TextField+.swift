//
//  TextField+Extension.swift
//  Haruhancut
//
//  Created by 김동현 on 4/14/25.
//

import UIKit
import ScaleKit

extension UITextField {
    func addLeftPadding() {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: DynamicSize.scaledSize(12), height: DynamicSize.scaledSize(50)))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setPlaceholderColor(color: UIColor) {
        guard let string = self.placeholder else {
            return
        }
        attributedPlaceholder = NSAttributedString(string: string, attributes: [.foregroundColor: color])
    }
}
