//
//  SamplePatternDotView.swift
//  PatternView-Sample
//
//  Created by jaume on 01/09/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit
import SwiftyPatternLock

public class SamplePatternDotView: UIView, PatternContainedView {

    var insideView: UIView!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    func setupView() {
        let insideView = UIView()
        insideView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(insideView)
        NSLayoutConstraint.activate([

            insideView.centerXAnchor.constraint(equalTo: centerXAnchor),
            insideView.centerYAnchor.constraint(equalTo: centerYAnchor),
            insideView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            insideView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.8)
            ])
        self.insideView = insideView
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        insideView.layer.cornerRadius = insideView.frame.height / 2

    }

    public func update(state: PatternContainedViewState) {
        switch state {
        case .notSelected: insideView.backgroundColor = UIColor(red: 190 / 255, green: 195 / 255, blue: 199 / 255, alpha: 1)
        case .selected: insideView.backgroundColor = UIColor(red: 216 / 255, green: 130 / 255, blue: 59 / 255, alpha: 1)
        case .error: insideView.backgroundColor = UIColor(red: 177 / 255, green: 67 / 255, blue: 52 / 255, alpha: 1)
        case .success: insideView.backgroundColor = UIColor(red: 101 / 255, green: 200 / 255, blue: 122 / 255, alpha: 1)
        }
    }
}
