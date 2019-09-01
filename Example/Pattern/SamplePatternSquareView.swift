//
//  SamplePatternSquareView.swift
//  PatternView-Sample
//
//  Created by jaume on 01/09/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit
import PatternViewController

public class SamplePatternSquareView: UIView, PatternContainedView {

    override public func layoutSubviews() {
        super.layoutSubviews()

        layer.borderWidth = 5
        layer.borderColor = UIColor.white.cgColor

    }

    public func update(state: PatternContainedViewState) {
        switch state {
        case .notSelected: backgroundColor = UIColor(red: 190 / 255, green: 195 / 255, blue: 199 / 255, alpha: 1)
        case .selected: backgroundColor = UIColor(red: 216 / 255, green: 130 / 255, blue: 59 / 255, alpha: 1)
        case .error: backgroundColor = UIColor(red: 177 / 255, green: 67 / 255, blue: 52 / 255, alpha: 1)
        case .success: backgroundColor = UIColor(red: 101 / 255, green: 200 / 255, blue: 122 / 255, alpha: 1)
        }
    }
}
