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

public protocol PatternDelegate: class {

    func created(pattern: [Int])
    func failedCreatingPattern(lenght: Int)
    func introducedPattern(ok: Bool)
    func endedShowingPattern()

}

public enum PatternContainedViewState {

    case notSelected, selected, error, success
}

public protocol PatternContainedView: UIView {

    func update(state: PatternContainedViewState)
}

public class SamplePatternView: UIView, PatternContainedView {

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

public class PatternViewController: UIViewController {

    public weak var delegate: PatternDelegate?

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
    private var passedPoints: [Int]!
    private var numberOfItemsPerRow = 3
    private var interpolate = false
    public var functionality: PatternFunctionality! {
        didSet { updateViews() }
    }
    private let animationBaseDuration = 0.3

    override public func viewDidLoad() {

        super.viewDidLoad()
        addSubViews()

    }

    override public func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()

        recalculatedCenters = false
        DispatchQueue.main.async {
            let isHigh = self.view.bounds.width < self.view.bounds.height
            self.widthAnchor.isActive = isHigh
            self.heightAnchor.isActive = !isHigh
            self.calculatePointCenters()
        }
    }

    func addSubViews() {

        view.backgroundColor = .black
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

    func updateViews() {

        if case .viewPattern(let pattern)? = functionality {
            resetViews()
            passedPoints = pattern
            drawPattern(indices: passedPoints)
        } else {
            resetViews()
        }
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
                updateViews(validPattern: false)
                delegate?.failedCreatingPattern(lenght: passedPoints.count)
            }

        case .checkPattern(let values)?:

            let isValid = passedPoints == values
            updateViews(validPattern: isValid)
            delegate?.introducedPattern(ok: isValid)

        default: return
        }
    }

    func resetViews() {

        guard recalculatedCenters else { return }

        CATransaction.begin()
        UIView.animate(withDuration: 0.3) {
            self.patternDotViews.forEach{ $0.update(state: .notSelected) }
            self.drawingLayer?.path = nil
        }
        CATransaction.commit()


    }

    func updateViews(validPattern: Bool) {

        CATransaction.begin()
        passedPoints.forEach{
            patternDotViews[$0].update(state: validPattern ? .success : .error)
        }
        CATransaction.commit()

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
            drawingLayer.lineWidth = 3
            drawingLayer.lineCap = .round
            drawingLayer.lineJoin = .round
        }

        guard let path = calculatePath(for: indices) else { return }
        if let endPoint = endPoint { path.addLine(to: endPoint) }

        let points = passedPoints.map { calculatePoint(from: $0) }
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

            passedPoints = pattern

            let pathAnimation = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
            let values: [NSNumber] = distances.map {

                totalSum += $0
                return NSNumber(value: totalSum / sum)

            }

            pathAnimation.keyTimes = values
            pathAnimation.values = values
            pathAnimation.duration = Double(passedPoints.count) * animationBaseDuration
            drawingLayer.add(pathAnimation, forKey: #keyPath(CAShapeLayer.path))
        } else {
            animate = false
        }

        CATransaction.begin()
        drawingLayer.path = path.cgPath

        totalSum = 0
        let delays: [Double] = distances.map {

            totalSum += $0
            return (totalSum / sum) * Double(passedPoints.count) * animationBaseDuration

        }
        passedPoints.enumerated().forEach { (offset, element) in

            let view = patternDotViews[element]
            UIView.animate(withDuration: 0.5, delay: animate ? (delays[offset] - 0.1) : 0, options: .overrideInheritedDuration, animations: {
                view.update(state: .selected)
            }, completion: { [weak self] _ in
                if animate && offset + 1 == self?.passedPoints?.count { //Shown last pattern dot
                    self?.delegate?.endedShowingPattern()
                }
            })
        }

        CATransaction.commit()
    }
}

extension PatternViewController { //Helper math funcs

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

    func calculatePoint(from index: Int) -> IntPoint {

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