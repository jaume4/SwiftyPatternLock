//
//  SamplePatternViewController.swift
//  PatternView-Sample
//
//  Created by jaume on 01/09/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit
import SwiftyPatternLock

extension UIViewController {

    @discardableResult
    func addContainedChildViewController<T: UIViewController>(_ vc: T.Type, onView: UIView) -> T {

        let viewController = vc.init()
        onView.addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: onView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: onView.trailingAnchor),
            viewController.view.topAnchor.constraint(equalTo: onView.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: onView.bottomAnchor)
            ])

        addChild(viewController)
        return viewController

    }
}

final class SampleViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!

    var vc: SwiftyPatternLock<SamplePatternDotView>!
//    var vc: PatternViewController<SamplePatternSquareView>!
    var pattern: [Int]!

    override func viewDidLoad() {
        super.viewDidLoad()

        addPatternVC()
        configPatternVC()

    }

    func addPatternVC() {
        vc = addContainedChildViewController(SwiftyPatternLock<SamplePatternDotView>.self, onView: containerView)
        vc.delegate = self
    }

    func configPatternVC() {

        let config = PatternViewConfig(backroundColor: .white,
                                       lineWidth: 4,
                                       lineDefaultColor: UIColor.darkGray.cgColor,
                                       lineValidColor: UIColor.green.cgColor,
                                       lineInvalidColor: UIColor.red.cgColor,
                                       numberOfItemsPerRow: 3)
        vc.setup(config)

    }

    @IBAction func create(_ sender: Any) {
        vc.functionality = .createPattern(3)
    }

    @IBAction func checkLast(_ sender: Any) {
        guard let pattern = pattern else { return }
        vc.functionality = .checkPattern(pattern)
    }

    @IBAction func showLast(_ sender: Any) {
        guard let pattern = pattern else { return }
        vc.functionality = .viewPattern((pattern: pattern, animated: false))
    }

    @IBAction func showLastAnimated(_ sender: Any) {
        guard let pattern = pattern else { return }
        vc.functionality = .viewPattern((pattern: pattern, animated: true))
    }

    @IBAction func clearPattern(_ sender: Any) {
        vc.clearPattern()
    }

}

extension SampleViewController: PatternDelegate {
    func created(pattern: [Int]) {
        print("Created pattern: \(pattern)")
        self.pattern = pattern
    }

    func failedCreatingPattern(lenght: Int) {
        print("Failed creating pattern")
    }

    func introducedPattern(valid: Bool) {
        print("Introduced pattarn is a match: \(valid)")
    }

    func endedShowingPattern() {
        print("Ended showing pattern")
    }

}
