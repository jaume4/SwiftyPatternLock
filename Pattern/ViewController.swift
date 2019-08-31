//
//  ViewController.swift
//  Pattern
//
//  Created by jaume on 28/08/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit

extension UIView {
    func pinEdges(to other: UIView) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: other.leadingAnchor),
            trailingAnchor.constraint(equalTo: other.trailingAnchor),
            topAnchor.constraint(equalTo: other.topAnchor),
            bottomAnchor.constraint(equalTo: other.bottomAnchor)
            ])

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

typealias IntPoint = (x: Int, y: Int)

class ViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!

    var locationOfBeganTap: CGPoint!
    var locationOfEndTap: CGPoint!
    var recalculatedCenters = false

    var parentStack: UIStackView!
    var childStacks: [UIStackView]!
    var drawingLayer: CAShapeLayer!
    var centers: [CGPoint]!
    var minDistance: CGFloat!
    var passedPoints: [Int]! {
        didSet {
            updateViews()
        }
    }
    var numberOfItemsPerRow = 3
    var interpolate = false

    override func viewDidLoad() {

        super.viewDidLoad()
        addSubViews()
    }

    override func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()
        recalculatedCenters = false
        DispatchQueue.main.async {
            self.calculatePointCenters()
        }
    }

    func addSubViews() {
        var stacks = [UIStackView]()

        for _ in 0..<numberOfItemsPerRow {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.distribution = .fillEqually
            stacks.append(stack)
            for _ in 0..<numberOfItemsPerRow {
                let view = UIView()
                view.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(view)
            }
        }
        parentStack = UIStackView(arrangedSubviews: stacks)
        parentStack.translatesAutoresizingMaskIntoConstraints = false
        parentStack.axis = .vertical
        parentStack.distribution = .fillEqually
        containerView.addSubview(parentStack)
        parentStack.pinEdges(to: containerView)
        childStacks = stacks

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didMove(gesture:)))
        containerView.addGestureRecognizer(panGesture)
    }

    func nearestPoint(from point: CGPoint) -> (index: Int, distance: CGFloat) {

        let distances = centers.map{ $0.distance(from: point) }
        let min = distances.min()!
        return (distances.firstIndex(where: {$0 == min})!, min)

    }

    func updateViews() {

        let passedPointsSet = Set(passedPoints)

        for i in 0..<numberOfItemsPerRow * numberOfItemsPerRow {
            if !passedPointsSet.contains(i) {
                let point = calculatePoint(from: i)
                let childStack = childStacks[point.x]
                childStack.arrangedSubviews[point.y].backgroundColor = .blue
            }
        }

        passedPoints.forEach{

            let point = calculatePoint(from: $0)
            let childStack = childStacks[point.x]
            childStack.arrangedSubviews[point.y].backgroundColor = .orange
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

    func isDiagonal(point1: IntPoint, point2: IntPoint) -> Bool {

        return abs(point1.x - point2.x) == abs(point1.y - point2.y)
    }

    func isOnSameLine(point1: IntPoint, point2: IntPoint) -> Bool {

        return point1.x == point2.x || point1.y == point2.y
    }

    func calculateLine(startPoint: IntPoint, endPoint: IntPoint) -> [IntPoint] {

        var dy = (endPoint.y - startPoint.y)
        var dx = (endPoint.x - startPoint.x)

        let incYi: Int
        if dy >= 0 { incYi = 1 } else { dy = -dy ; incYi = -1 }

        let incXi: Int
        if dx >= 0 { incXi = 1 } else { dx = -dx ; incXi = -1 }

        let incYr, incXr: Int
        if dx >= dy {
            incYr = 0
            incXr = incXi
        } else {
            incXr = 0
            incYr = incYi
            (dx, dy) = (dy, dx)
        }

        var x = startPoint.x
        var y = startPoint.y
        let avR = 2 * dy
        var av = avR - dx
        let avI = av - dx

        var points = [IntPoint]()
        while x != endPoint.x || y != endPoint.y {
            if av >= 0 {
                x = x + incXi
                y = y + incYi
                av = av + avI
            } else {
                x = x + incXr
                y = y + incYr
                av = av + avR
            }

            let point = (x, y)
            if interpolate {
                points.append(point)
            } else {
                let onSameLine = isOnSameLine(point1: startPoint, point2: point) && isOnSameLine(point1: endPoint, point2: point)
                let onDiagonal = isDiagonal(point1: startPoint, point2: point) && isDiagonal(point1: endPoint, point2: point)
                if onSameLine || onDiagonal {
                    points.append(point)
                }
            }
        }

        return points
    }

    func calculatePoint(from index: Int) -> IntPoint {

        let indexX = index / numberOfItemsPerRow
        let indexY = index % numberOfItemsPerRow
        return (indexX, indexY)
    }

    func calculateIndex(for point: IntPoint) -> Int {

         return point.x * numberOfItemsPerRow + point.y
    }

    func calculatePointCenters() {

        if recalculatedCenters { return }
        recalculatedCenters = true
        var calculatedMinDistance = false

        centers = parentStack.arrangedSubviews.flatMap { stack in
            (stack as! UIStackView).arrangedSubviews.compactMap{

                if !calculatedMinDistance {
                    minDistance = $0.frame.width / 3
                    calculatedMinDistance = true
                }
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

        let point1 = calculatePoint(from: passedPoints.last!)
        let point2 = calculatePoint(from: index)

        let points = calculateLine(startPoint: point1, endPoint: point2)
        let indices = points.map { calculateIndex(for: $0) }

        if distance < minDistance, !passedPoints.contains(index) {
            passedPoints.append(contentsOf: indices.filter{ !passedPoints.contains($0) })
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

