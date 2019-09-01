//
//  SamplePatternViewController.swift
//  PatternView-Sample
//
//  Created by jaume on 01/09/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit
import PatternViewController

final class SampleViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!

//    Provide a PatternContainedView
//    var vc: PatternViewController<SamplePatternView>!
    var vc: PatternViewController<SamplePatternSquareView>!
    var pattern: [Int]!

    override func viewDidLoad() {
        super.viewDidLoad()

        addPatternVC()
        configPatternVC()

    }

    func addPatternVC() {
//        vc = PatternViewController<SamplePatternDotView>()
        vc = PatternViewController<SamplePatternSquareView>()
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(vc.view)
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

        addChild(vc)
        vc.delegate = self
    }

    func configPatternVC() {

        let config = PatternViewConfig(backroundColor: .white, lineWidth: 4, lineColor: UIColor.darkGray.cgColor, numberOfItemsPerRow: 4)
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
        vc.functionality = .viewPattern(pattern)
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
