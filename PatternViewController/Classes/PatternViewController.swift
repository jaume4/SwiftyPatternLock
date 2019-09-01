//
//  PatternViewController.swift
//  PatternViewController
//
//  Created by jaume on 28/08/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit
import os.log

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

public struct PatternViewConfig {

    let backroundColor: UIColor
    let lineWidth: CGFloat
    let lineColor: CGColor
    let numberOfItemsPerRow: Int

    public init(backroundColor: UIColor, lineWidth: CGFloat, lineColor: CGColor, numberOfItemsPerRow: Int) {
        self.backroundColor = backroundColor
        self.lineWidth = lineWidth
        self.lineColor = lineColor
        self.numberOfItemsPerRow = numberOfItemsPerRow
    }

}

public protocol PatternDelegate: class {

    func created(pattern: [Int])
    func failedCreatingPattern(lenght: Int)
    func introducedPattern(valid: Bool)
    func endedShowingPattern()

}

public enum PatternContainedViewState {

    case notSelected, selected, error, success
}

public protocol PatternContainedView: UIView {

    func update(state: PatternContainedViewState)
}

public class PatternViewController<T: PatternContainedView>: UIViewController {

    public weak var delegate: PatternDelegate?

    private var locationOfBeganTap: CGPoint!
    private var locationOfEndTap: CGPoint!
    private var recalculatedCenters = false
    private var widthAnchor: NSLayoutConstraint!
    private var heightAnchor: NSLayoutConstraint!

    private var config: PatternViewConfig!
    private var parentStack: UIStackView!
    private var patternDotViews: [T]!
    private var drawingLayer: CAShapeLayer!
    private var centers: [CGPoint]!
    private var minDistance: CGFloat!
    private var passedPointsIndices: [Int]!
    private var numberOfItemsPerRow: Int!
    private var interpolate = false
    public var functionality: PatternFunctionality! {
        didSet { updateViews() }
    }
    private let animationBaseDuration = 0.3

    override public func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()

        guard config != nil else { return }

        recalculatedCenters = false
        DispatchQueue.main.async {
            let isHigh = self.view.bounds.width < self.view.bounds.height
            self.widthAnchor.isActive = isHigh
            self.heightAnchor.isActive = !isHigh
            self.calculatePointCenters()
            if let drawingLayer = self.drawingLayer, let points = self.passedPointsIndices, let path = self.calculatePath(for: points) { //Recalculate path
                drawingLayer.path = path.cgPath
            }
        }
    }

    public func setup(_ config: PatternViewConfig) {
        self.config = config
        self.numberOfItemsPerRow = config.numberOfItemsPerRow
        view.backgroundColor = config.backroundColor

        addSubViews()
    }

    func addSubViews() {

        var stacks = [UIStackView]()
        patternDotViews = [T]()

        for _ in 0..<numberOfItemsPerRow {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.distribution = .fillEqually
            stacks.append(stack)
            for _ in 0..<numberOfItemsPerRow {
                let view = T()
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

    func setupShapeLayer() {
        drawingLayer = CAShapeLayer()
        parentStack.layer.insertSublayer(drawingLayer, above: parentStack.layer)
        drawingLayer.strokeColor = config.lineColor
        drawingLayer.lineWidth = config.lineWidth
        drawingLayer.lineCap = .round
        drawingLayer.lineJoin = .round
    }

    func updateViews() {

        if case .viewPattern(let pattern)? = functionality {
            resetViews()
            passedPointsIndices = pattern
            draw(indices: passedPointsIndices)
        } else {
            resetViews()
        }
    }

    func resetViews() {

        guard recalculatedCenters else { return }

        CATransaction.begin()
        UIView.animate(withDuration: animationBaseDuration, delay: 0, options: .beginFromCurrentState, animations: {
            self.patternDotViews.forEach{ $0.update(state: .notSelected) }
            self.drawingLayer?.removeAllAnimations()
            self.drawingLayer?.path = nil
        }, completion: nil)
        CATransaction.commit()

    }

    func updateViews(validPattern: Bool) {

        CATransaction.begin()
        passedPointsIndices.forEach{
            patternDotViews[$0].update(state: validPattern ? .success : .error)
        }
        CATransaction.commit()

    }

    @objc func didMove(gesture: UIPanGestureRecognizer) {

        if case .viewPattern? = functionality { return }
        guard functionality != nil else { return }

        switch gesture.state {

        case .began:

            resetViews()
            calculatePointCenters()
            locationOfBeganTap = gesture.location(in: parentStack)
            let nearest = nearestPoint(from: locationOfBeganTap)
            passedPointsIndices = [nearest.index]
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

            let isValid = passedPointsIndices.count >= min
            if isValid {
                delegate?.created(pattern: passedPointsIndices)
            } else {
                updateViews(validPattern: false)
                delegate?.failedCreatingPattern(lenght: passedPointsIndices.count)
            }

        case .checkPattern(let values)?:

            let isValid = passedPointsIndices == values
            updateViews(validPattern: isValid)
            delegate?.introducedPattern(valid: isValid)

        default: return
        }
    }

    func checkIfIsPassingPoint(index: Int, distance: CGFloat, isEnd: Bool = false) {

        defer { draw(indices: passedPointsIndices, endPoint: isEnd ? nil : locationOfEndTap) }

        guard distance < minDistance else { return }

        let point1 = calculatePoint(index: passedPointsIndices.last!)
        let point2 = calculatePoint(index: index)

        let points = calculateLine(startPoint: point1, endPoint: point2)
        let indices = points.map { calculateIndex(for: $0) }

        if !passedPointsIndices.contains(index) {
            if !points.isEmpty {
                passedPointsIndices.append(contentsOf: indices.filter{ !passedPointsIndices.contains($0) })
            } else {
                passedPointsIndices.append(index)
            }
        }

    }

    func draw(indices: [Int], endPoint: CGPoint? = nil) {

        if drawingLayer == nil { setupShapeLayer() }

        guard let path = calculatePath(for: indices) else { return }
        if let endPoint = endPoint { path.addLine(to: endPoint) }

        let points = passedPointsIndices.map { calculatePoint(index: $0) }
        let distances: [Double] = points.enumerated().map{
            if $0.offset == 0 { return 0 }
            return distance(from: $0.element, to: points[$0.offset - 1])
        }
        let sum = distances.reduce(0, {$0 + $1})
        var totalSum = 0.0

        let animate: Bool

        //Animation
        if case .viewPattern(let pattern)? = functionality {

            animate = true
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

            passedPointsIndices = pattern

            let pathAnimation = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
            let values: [NSNumber] = distances.map {

                totalSum += $0
                return NSNumber(value: totalSum / sum)

            }

            pathAnimation.keyTimes = values
            pathAnimation.values = values
            pathAnimation.duration = Double(passedPointsIndices.count) * animationBaseDuration
            drawingLayer.add(pathAnimation, forKey: #keyPath(CAShapeLayer.path))
        } else {
            animate = false
        }

        CATransaction.begin()
        drawingLayer.path = path.cgPath

        totalSum = 0
        let delays: [Double] = distances.map {

            totalSum += $0
            return (totalSum / sum) * Double(passedPointsIndices.count) * animationBaseDuration

        }
        passedPointsIndices.enumerated().forEach { (offset, element) in

            let view = patternDotViews[element]
            UIView.animate(withDuration: animationBaseDuration, delay: animate ? (delays[offset] - 0.1) : 0, options: .overrideInheritedDuration, animations: {
                view.update(state: .selected)
            }, completion: { [weak self] _ in
                if animate && offset + 1 == self?.passedPointsIndices?.count { //Shown last pattern dot
                    self?.delegate?.endedShowingPattern()
                }
            })
        }

        CATransaction.commit()
    }
}

extension PatternViewController { //Helper math and calculator funcs

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

    func nearestPoint(from point: CGPoint) -> (index: Int, distance: CGFloat) {

        let distances = centers.map{ $0.distance(from: point) }
        let min = distances.min()!
        return (distances.firstIndex(where: {$0 == min})!, min)

    }

    func distance(from: IntPoint, to: IntPoint) -> Double {
        let x = (from.x - to.x)
        let y = (from.y - to.y)
        return sqrt(Double(x * x + y * y))
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

    func calculatePoint(index: Int) -> IntPoint {

        let indexX = index / numberOfItemsPerRow
        let indexY = index % numberOfItemsPerRow
        return (indexX, indexY)
    }

    func calculateIndex(for point: IntPoint) -> Int {

        return point.x * numberOfItemsPerRow + point.y
    }

    func calculatePointCenters() {

        guard !recalculatedCenters else { return }
        recalculatedCenters = true
        var calculatedMinDistance = false

        let newCenters: [CGPoint] = patternDotViews.compactMap {

            if !calculatedMinDistance {
                minDistance = $0.frame.width / 3
                calculatedMinDistance = true
            }

            return $0.convert($0.bounds, to: parentStack).center

        }

        guard newCenters != centers else { return }
        centers = newCenters

    }
}
