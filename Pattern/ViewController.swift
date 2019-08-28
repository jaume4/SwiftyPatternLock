//
//  ViewController.swift
//  Pattern
//
//  Created by jaume on 28/08/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit

extension UIColor {

    static func random(hue: CGFloat = CGFloat.random(in: 0...1),
                       saturation: CGFloat = CGFloat.random(in: 0.5...1), // from 0.5 to 1.0 to stay away from white
        brightness: CGFloat = CGFloat.random(in: 0.5...1), // from 0.5 to 1.0 to stay away from black
        alpha: CGFloat = 1) -> UIColor {
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}

extension UIView {
    func pinEdges(to other: UIView) {
        leadingAnchor.constraint(equalTo: other.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
    }
}

extension CGPoint {
    func distance(from point: CGPoint) -> CGFloat {
        let dx = point.x - x
        let dy = point.y - y
        return sqrt((dx * dx) + (dy * dy))
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!

    var locationOfBeganTap: CGPoint!
    var locationOfEndTap: CGPoint!
    var recalculatedCenters = false

    var parentStack: UIStackView!
    var drawingLayer: CAShapeLayer!
    var centers: [CGPoint]!
    var minDistance: CGFloat!
    var passedPoints: [Int]! {
        didSet {
            updateViews()
        }
    }
    var numberOfItemsPerRow = 4

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.


        var index = 0
        var stacks = [UIStackView]()

        for _ in 0..<numberOfItemsPerRow {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.distribution = .fillEqually
            stacks.append(stack)
            for _ in 0..<numberOfItemsPerRow {
                let view = UIView()
                view.accessibilityIdentifier = "\(index)"
                index += 1
                view.translatesAutoresizingMaskIntoConstraints = false
                view.backgroundColor = UIColor.random()
                stack.addArrangedSubview(view)
            }
        }
        parentStack = UIStackView(arrangedSubviews: stacks)
        parentStack.translatesAutoresizingMaskIntoConstraints = false
        parentStack.axis = .vertical
        parentStack.distribution = .fillEqually
        containerView.addSubview(parentStack)
        parentStack.pinEdges(to: containerView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didMove(gesture:)))
        containerView.addGestureRecognizer(panGesture)

    }

    func nearestPoint(from point: CGPoint) -> (index: Int, distance: CGFloat) {

        let distances = centers.map{ $0.distance(from: point) }
        let min = distances.min()!
        return (distances.firstIndex(where: {$0 == min})!, min)

    }

    func updateViews() {
        passedPoints.forEach{
            let stack = $0 / numberOfItemsPerRow
            let index = $0 % numberOfItemsPerRow
            let childStack = parentStack.arrangedSubviews[stack] as! UIStackView
            childStack.arrangedSubviews[index].backgroundColor = .orange
        }
    }

    @objc func didMove(gesture: UIPanGestureRecognizer) {

        switch gesture.state {
        case .began:

            calculatePointCenters()
            locationOfBeganTap = gesture.location(in: parentStack)
            let nearest = nearestPoint(from: locationOfBeganTap)
            passedPoints = [nearest.index]
            locationOfBeganTap = centers[nearest.index]
            locationOfEndTap = gesture.location(in: containerView)
            draw(index: nearest.index, distance: nearest.distance)
        case .changed:
            locationOfEndTap = gesture.location(in: containerView)
            let nearest = nearestPoint(from: locationOfEndTap)
            draw(index: nearest.index, distance: nearest.distance)
        case .ended:
            locationOfEndTap = gesture.location(in: containerView)
            let nearest = nearestPoint(from: locationOfEndTap)
            draw(index: nearest.index, distance: nearest.distance, ending: true)
        default: return
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recalculatedCenters = false
    }

    func isDiagonal(index1: Int, index2: Int) -> Bool {
        let index1x = index1 / numberOfItemsPerRow
        let index1y = index1 % numberOfItemsPerRow
        let index2x = index2 / numberOfItemsPerRow
        let index2y = index2 % numberOfItemsPerRow
        return abs(index1x-index2x) == abs(index1y - index2y)
    }

    func calculatePointCenters() {

        if recalculatedCenters { return }
        recalculatedCenters = true

        centers = parentStack.arrangedSubviews.flatMap { stack in
            (stack as! UIStackView).arrangedSubviews.compactMap{

                if $0.accessibilityIdentifier == "0" { minDistance = $0.frame.width / 3 }
                $0.backgroundColor = .blue
                $0.layer.cornerRadius = $0.frame.width / 2
                return $0.convert($0.bounds, to: containerView).center
            }
        }

    }

    func draw(index: Int, distance: CGFloat, ending: Bool = false) {

        if drawingLayer == nil {
            drawingLayer = CAShapeLayer()
            containerView.layer.insertSublayer(drawingLayer, above: containerView.layer)
        }

        print(distance < minDistance && !passedPoints.contains(index))
        print(index)

        if !isDiagonal(index1: passedPoints.last!, index2: index), distance < minDistance, !passedPoints.contains(index) {
            passedPoints.append(index)
        }

        let path = UIBezierPath()
        path.move(to: locationOfBeganTap)
        passedPoints.forEach {
            path.addLine(to: centers[$0])
            path.move(to: centers[$0])
        }
        if !ending {path.addLine(to: locationOfEndTap)}


        drawingLayer.path = path.cgPath
        drawingLayer.strokeColor = UIColor.red.cgColor
        drawingLayer.lineWidth = 2

    }


}

