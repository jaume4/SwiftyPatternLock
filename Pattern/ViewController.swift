//
//  ViewController.swift
//  Pattern
//
//  Created by jaume on 28/08/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit
import os.log

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

public enum PatternFunctionality {
    case createPattern(Int), checkPattern([Int]), viewPattern([Int])
}

public protocol PatternDelegate: class {

    func created(pattern: [Int])
    func failedCreatingPattern(lenght: Int)
    func introducedPattern(ok: Bool)

}

public enum PatternContainedViewState {

    case notSelected, selected, error, success
}

public protocol PatternContainedView: UIView {

    func update(state: PatternContainedViewState)
}

public class SamplePatternView: UIView, PatternContainedView {
    public func update(state: PatternContainedViewState) {
        switch state {
        case .notSelected: backgroundColor = UIColor(red: 190 / 255, green: 195 / 255, blue: 199 / 255, alpha: 1)
        case .selected: backgroundColor = UIColor(red: 216 / 255, green: 130 / 255, blue: 59 / 255, alpha: 1)
        case .error: backgroundColor = UIColor(red: 177 / 255, green: 67 / 255, blue: 52 / 255, alpha: 1)
        case .success: backgroundColor = UIColor(red: 101 / 255, green: 200 / 255, blue: 122 / 255, alpha: 1)
        }
    }
}

public class ViewController: UIViewController {

    private weak var delegate: PatternDelegate?

    private var locationOfBeganTap: CGPoint!
    private var locationOfEndTap: CGPoint!
    private var recalculatedCenters = false
    private var widthAnchor: NSLayoutConstraint!
    private var heightAnchor: NSLayoutConstraint!

    private var parentStack: UIStackView!
    private var patternDotViews: [UIView & PatternContainedView]!
    private var drawingLayer: CAShapeLayer!
    private var centers: [CGPoint]!
    private var minDistance: CGFloat!
    private var passedPoints: [Int]! {
        didSet {
            updateViews()
        }
    }
    private var numberOfItemsPerRow = 3
    private var interpolate = false
    private var functionality: PatternFunctionality!

    override public func viewDidLoad() {

        super.viewDidLoad()
        addSubViews()

        //    var functionality = PatternFunctionality.createPattern(3)
        //    private var functionality = PatternFunctionality.checkPattern([0,3,6,7])
        functionality = PatternFunctionality.viewPattern([0,3,6,7])

    }

    override public func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()
        recalculatedCenters = false
        DispatchQueue.main.async {
            let isHigh = self.view.bounds.width < self.view.bounds.height
            self.widthAnchor.isActive = isHigh
            self.heightAnchor.isActive = !isHigh
            self.calculatePointCentersAndUpdateSubViews()
            if let points = self.passedPoints {
                self.drawPattern(indices: points)
            }
        }
    }

    func addSubViews() {

        view.backgroundColor = .clear
        var stacks = [UIStackView]()
        patternDotViews = [UIView & PatternContainedView]()

        for _ in 0..<numberOfItemsPerRow {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.distribution = .fillEqually
            stacks.append(stack)
            for _ in 0..<numberOfItemsPerRow {
                let view = SamplePatternView()
                view.update(state: .notSelected)
                view.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(view)
                patternDotViews.append(view)
            }
        }
        parentStack = UIStackView(arrangedSubviews: stacks)
        parentStack.translatesAutoresizingMaskIntoConstraints = false
        parentStack.axis = .vertical
        parentStack.distribution = .fillEqually
        view.addSubview(parentStack)
        heightAnchor = parentStack.heightAnchor.constraint(equalTo: view.heightAnchor)
        widthAnchor = parentStack.widthAnchor.constraint(equalTo: view.widthAnchor)
        NSLayoutConstraint.activate([
            parentStack.widthAnchor.constraint(equalTo: parentStack.heightAnchor),
            parentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            parentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didMove(gesture:)))
        parentStack.addGestureRecognizer(panGesture)
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
                let view = patternDotViews[i]
                view.update(state: .notSelected)
            }
        }

        passedPoints.forEach {

            let view = patternDotViews[$0]
            view.update(state: .selected)
        }
    }

    @objc func didMove(gesture: UIPanGestureRecognizer) {

        if case .viewPattern? = functionality { return }
        guard functionality != nil else { return }

        switch gesture.state {

        case .began:

            calculatePointCentersAndUpdateSubViews()
            locationOfBeganTap = gesture.location(in: parentStack)
            let nearest = nearestPoint(from: locationOfBeganTap)
            passedPoints = [nearest.index]
            locationOfBeganTap = centers[nearest.index]
            locationOfEndTap = gesture.location(in: parentStack)
            checkIfIsPassingPoint(index: nearest.index, distance: nearest.distance)

        case .changed:

            locationOfEndTap = gesture.location(in: parentStack)
            let nearest = nearestPoint(from: locationOfEndTap)
            checkIfIsPassingPoint(index: nearest.index, distance: nearest.distance)

        case .ended:

            locationOfEndTap = gesture.location(in: parentStack)
            let nearest = nearestPoint(from: locationOfEndTap)
            checkIfIsPassingPoint(index: nearest.index, distance: nearest.distance, isEnd: true)
            endedEnteringPattern()

        default: return
        }

    }

    func endedEnteringPattern() {

        switch functionality {
        case .createPattern(let min)?:

            let isValid = passedPoints.count >= min
            if isValid {
                delegate?.created(pattern: passedPoints)
            } else {
                delegate?.failedCreatingPattern(lenght: passedPoints.count)
            }
            print(passedPoints!)
            print(isValid)

        case .checkPattern(let values)?:

            let isValid = passedPoints == values
            updateViews(validPattern: isValid)
            delegate?.introducedPattern(ok: isValid)

        default: return
        }
    }

    func updateViews(validPattern: Bool) {

        passedPoints.forEach{
            patternDotViews[$0].update(state: validPattern ? .success : .error)
        }

    }

    func drawPattern(indices: [Int]) {
        draw(indices: indices, endPoint: nil)
    }

    func checkIfIsPassingPoint(index: Int, distance: CGFloat, isEnd: Bool = false) {

        defer { draw(indices: passedPoints, endPoint: isEnd ? nil : locationOfEndTap) }

        guard distance < minDistance else { return }

        let point1 = calculatePoint(from: passedPoints.last!)
        let point2 = calculatePoint(from: index)

        let points = calculateLine(startPoint: point1, endPoint: point2)
        let indices = points.map { calculateIndex(for: $0) }

        if !passedPoints.contains(index) {
            if !points.isEmpty {
                passedPoints.append(contentsOf: indices.filter{ !passedPoints.contains($0) })
            } else {
                passedPoints.append(index)
            }
        }

    }

    func calculatePath(for points: [Int]) -> UIBezierPath? {

        guard let first = points.first else { return nil }

        let path = UIBezierPath()
        path.move(to: centers[first])
        for i in 1..<points.count {
            let point = points[i]
            path.addLine(to: centers[point])
            path.move(to: centers[point])
        }

        return path

    }

    func draw(indices: [Int], endPoint: CGPoint?) {

        if drawingLayer == nil {
            drawingLayer = CAShapeLayer()
            parentStack.layer.insertSublayer(drawingLayer, above: parentStack.layer)
            drawingLayer.strokeColor = UIColor.white.cgColor
            drawingLayer.lineWidth = 5
            drawingLayer.lineCap = .round
        }

        guard let path = calculatePath(for: indices) else { return }
        if let endPoint = endPoint { path.addLine(to: endPoint) }

//        //Animation
//        let pathAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
//        pathAnimation.fromValue = 0
//        pathAnimation.toValue = 1
//        pathAnimation.duration = Double(passedPoints.count) * 0.2
//
////        drawingLayer.path = initialPath.cgPath
//        drawingLayer.add(pathAnimation, forKey: #keyPath(CAShapeLayer.path))
        drawingLayer.path = path.cgPath

    }
}

extension ViewController { //Helper math funcs

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

    func calculatePointCentersAndUpdateSubViews() {

        guard !recalculatedCenters else { return }
        recalculatedCenters = true
        var calculatedMinDistance = false

        centers = patternDotViews.compactMap {

            if !calculatedMinDistance {
                minDistance = $0.frame.width / 3
                calculatedMinDistance = true
            }

            $0.layer.cornerRadius = $0.frame.width / 2
            return $0.convert($0.bounds, to: parentStack).center

        }

        if case let .viewPattern(pattern)? = functionality {

            let patternSet = Set(pattern)

            guard patternSet.count == pattern.count,
                let max = pattern.max(), max < numberOfItemsPerRow * numberOfItemsPerRow,
                let min = pattern.min(), min >= 0 else { //Invalid pattern

                if #available(iOS 12.0, *) {
                    os_log(.error, "Invalid pattern received")
                } else {
                   NSLog("Invalid pattern received")
                }
                return

            }
            passedPoints = pattern
            drawPattern(indices: pattern)
        }
    }

}
