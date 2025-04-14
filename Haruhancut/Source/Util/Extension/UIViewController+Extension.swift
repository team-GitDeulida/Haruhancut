//
//  UIViewController+Extension.swift
//  Haruhancut
//
//  Created by 김동현 on 4/14/25.
//
/*
 https://peppo.tistory.com/62
 */

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
