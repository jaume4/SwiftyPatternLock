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

    var vc: PatternViewController<SamplePatternView>!
    var pattern: [Int]!

    override func viewDidLoad() {
        super.viewDidLoad()

        addPatternVC()

    }

    func addPatternVC() {
        vc = PatternViewController<SamplePatternView>()
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

    func introducedPattern(ok: Bool) {
        print("Introduced pattarn matches pattern: \(ok)")
    }

    func endedShowingPattern() {
        print("Ended showing pattern")
    }

}
