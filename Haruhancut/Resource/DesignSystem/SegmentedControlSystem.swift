//
//  SegmentedControlSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 6/2/25.
//

import UIKit

final class CustomSegmentedBarView: UIView {
    let segmentedControl: UISegmentedControl
    private let underlineView = UIView()
    private var underlineLeadingConstraint: NSLayoutConstraint!
    private var underlineWidthConstraint: NSLayoutConstraint!
    private let underlineHeight: CGFloat = 4.0

    init(items: [String]) {
        self.segmentedControl = UISegmentedControl(items: items)
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setup() {
        
        let image = UIImage()
        segmentedControl.setBackgroundImage(image, for: .normal, barMetrics: .default)
        segmentedControl.setBackgroundImage(image, for: .selected, barMetrics: .default)
        segmentedControl.setBackgroundImage(image, for: .highlighted, barMetrics: .default)
        segmentedControl.setDividerImage(image, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        
        // 스타일 커스텀
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.gray,
            .font: UIFont.systemFont(ofSize: 15, weight: .bold)
        ], for: .normal)
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.mainWhite,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ], for: .selected)
        
        // 스타일
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        underlineView.backgroundColor = .mainWhite

        addSubview(segmentedControl)
        addSubview(underlineView)

        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),

            underlineView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: underlineHeight),
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        // 동적 width/leading
        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: leadingAnchor)
        underlineWidthConstraint = underlineView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0 / CGFloat(segmentedControl.numberOfSegments))
        NSLayoutConstraint.activate([underlineLeadingConstraint, underlineWidthConstraint])

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    @objc private func segmentChanged() {
        moveUnderline(animated: true)
    }

    func moveUnderline(animated: Bool) {
        layoutIfNeeded()
        let count = CGFloat(segmentedControl.numberOfSegments)
        let segmentWidth = bounds.width / max(count, 1)
        underlineLeadingConstraint.constant = segmentWidth * CGFloat(segmentedControl.selectedSegmentIndex)
        if animated {
            UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
        } else {
            self.layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        moveUnderline(animated: false)
    }
}
