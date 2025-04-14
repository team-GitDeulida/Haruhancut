//
//  ColorSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 4/14/25.
//

import UIKit

enum HCColor {
    case background
    case mainBlack
    case mainWHite
}

extension UIColor {
    static let background = UIColor(hex: "#1A1A1A")
    static let mainBlack = UIColor(hex: "#161717")
    static let mainWhite = UIColor(hex: "#f1f1f1")
    
    static let kakao = UIColor(hex: "#FEE500")
    static let apple = UIColor(hex: "#FFFFFF")
    
    static let Gray000 = UIColor(hex: "#EFEFEF")
    static let Gray100 = UIColor(hex: "#B0AEB3")
    static let Gray200 = UIColor(hex: "#8B888F")
    static let Gray300 = UIColor(hex: "#67646C")
    static let Gray500 = UIColor(hex: "#454348")
    static let Gray700 = UIColor(hex: "#252427")
    static let Gray900 = UIColor(hex: "#111113")
}
