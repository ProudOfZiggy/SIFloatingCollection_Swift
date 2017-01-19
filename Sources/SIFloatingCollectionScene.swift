//
//  SIFloatingCollectionScene.swift
//  SIFloatingCollectionExample_Swift
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import SpriteKit

public func distanceBetweenPoints(_ firstPoint: CGPoint, secondPoint: CGPoint) -> CGFloat {
    return hypot(secondPoint.x - firstPoint.x, secondPoint.y - firstPoint.y)
}

@objc public protocol SIFloatingCollectionSceneDelegate {
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, shouldSelectFloatingNodeAtIndex index: Int) -> Bool
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, didSelectFloatingNodeAtIndex index: Int)
    
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, shouldDeselectFloatingNodeAtIndex index: Int) -> Bool
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, didDeselectFloatingNodeAtIndex index: Int)
    
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, startedRemovingOfFloatingNodeAtIndex index: Int)
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, canceledRemovingOfFloatingNodeAtIndex index: Int)
    
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, shouldRemoveFloatingNodeAtIndex index: Int) -> Bool
    @objc optional func floatingScene(_ scene: SIFloatingCollectionScene, didRemoveFloatingNodeAtIndex index: Int)
}

public enum SIFloatingCollectionSceneMode {
    case normal
    case editing
    case moving
}

open class SIFloatingCollectionScene: SKScene {
    fileprivate(set) open var magneticField = SKFieldNode.radialGravityField()
    fileprivate(set) var mode: SIFloatingCollectionSceneMode = .normal {
        didSet {
            modeUpdated()
        }
    }
    fileprivate(set) open var floatingNodes: [SIFloatingNode] = []
    
    fileprivate var touchPoint: CGPoint?
    fileprivate var touchStartedTime: TimeInterval?
    fileprivate var removingStartedTime: TimeInterval?
    
    open var timeToStartRemove: TimeInterval = 0.7
    open var timeToRemove: TimeInterval = 2
    open var allowEditing = false
    open var allowMultipleSelection = true
    open var restrictedToBounds = true
    open var pushStrength: CGFloat = 10000
    open weak var floatingDelegate: SIFloatingCollectionSceneDelegate?
    
    override open func didMove(to view: SKView) {
        super.didMove(to: view)
        configure()
    }
    
    // MARK: -
    // MARK: Frame Updates
    //@todo refactoring
    override open func update(_ currentTime: TimeInterval) {
        let _ = floatingNodes.map { (node: SKNode) -> Void in
            let distanceFromCenter = distanceBetweenPoints(self.magneticField.position, secondPoint: node.position)
            node.physicsBody?.linearDamping = distanceFromCenter > 100 ? 2 : 2 + ((100 - distanceFromCenter) / 10)
        }
        
        if mode == .moving || !allowEditing {
            return
        }
        
        if let tStartTime = touchStartedTime, let tPoint = touchPoint {
            let dTime = currentTime - tStartTime
            if dTime >= timeToStartRemove {
                touchStartedTime = nil
                if let node = atPoint(tPoint) as? SIFloatingNode {
                    removingStartedTime = currentTime
                    startRemovingNode(node)
                }
            }
        } else if mode == .editing, let tRemovingTime = removingStartedTime, let tPoint = touchPoint {
            let dTime = currentTime - tRemovingTime
            if dTime >= timeToRemove {
                removingStartedTime = nil
                if let node = atPoint(tPoint) as? SIFloatingNode {
                    if let index = floatingNodes.index(of: node) {
                        removeFloatinNodeAtIndex(index)
                    }
                }
            }
        }
    }
    
    // MARK: -
    // MARK: Touching Handlers
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first as UITouch? {
            touchPoint = touch.location(in: self)
            touchStartedTime = touch.timestamp
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode == .editing {
            return
        }
        
        if let touch = touches.first as UITouch? {
            let plin = touch.previousLocation(in: self)
            let lin = touch.location(in: self)
            var dx = lin.x - plin.x
            var dy = lin.y - plin.y
            let b = sqrt(pow(lin.x, 2) + pow(lin.y, 2))
            dx = b == 0 ? 0 : (dx / b)
            dy = b == 0 ? 0 : (dy / b)
            
            if dx == 0 && dy == 0 {
                return
            } else if mode != .moving {
                mode = .moving
            }
            
            for node in floatingNodes {
                let w = node.frame.size.width / 2
                let h = node.frame.size.height / 2
                var direction = CGVector(
                    dx: CGFloat(self.pushStrength) * dx,
                    dy: CGFloat(self.pushStrength) * dy
                )
                
                if restrictedToBounds {
                    if !(-w...size.width + w ~= node.position.x) && (node.position.x * dx > 0) {
                        direction.dx = 0
                    }
                    
                    if !(-h...size.height + h ~= node.position.y) && (node.position.y * dy > 0) {
                        direction.dy = 0
                    }
                }
                node.physicsBody?.applyForce(direction)
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode != .moving, let touch = touchPoint {
            if let node = atPoint(touch) as? SIFloatingNode {
                updateNodeState(node)
            }
        }
        mode = .normal
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        mode = .normal
    }
    
    // MARK: -
    // MARK: Nodes Manipulation
    fileprivate func cancelRemovingNode(_ node: SIFloatingNode!) {
        mode = .normal
        node.physicsBody?.isDynamic = true
        node.state = node.previousState
        if let index = floatingNodes.index(of: node) {
            floatingDelegate?.floatingScene?(self, canceledRemovingOfFloatingNodeAtIndex: index)
        }
    }
    
    open func floatingNodeAtIndex(_ index: Int) -> SIFloatingNode? {
        if index < floatingNodes.count && index >= 0 {
            return floatingNodes[index]
        }
        return nil
    }
    
    open func indexOfSelectedNode() -> Int? {
        var index: Int?
        
        for (idx, node) in floatingNodes.enumerated() {
            if node.state == .selected {
                index = idx
                break
            }
        }
        return index
    }
    
    open func indexesOfSelectedNodes() -> [Int]! {
        var indexes: [Int] = []
        
        for (idx, node) in floatingNodes.enumerated() {
            if node.state == .selected {
                indexes.append(idx)
            }
        }
        return indexes
    }
    
    override open func atPoint(_ p: CGPoint) -> SKNode {
        var currentNode = super.atPoint(p)
        
        while !(currentNode.parent is SKScene) && !(currentNode is SIFloatingNode)
            && (currentNode.parent != nil) && !currentNode.isUserInteractionEnabled {
                currentNode = currentNode.parent!
        }
        return currentNode
    }
    
    open func removeFloatinNodeAtIndex(_ index: Int) {
        if shouldRemoveNodeAtIndex(index) {
            let node = floatingNodes[index]
            floatingNodes.remove(at: index)
            node.removeFromParent()
            floatingDelegate?.floatingScene?(self, didRemoveFloatingNodeAtIndex: index)
        }
    }
    
    fileprivate func startRemovingNode(_ node: SIFloatingNode!) {
        mode = .editing
        node.physicsBody?.isDynamic = false
        node.state = .removing
        if let index = floatingNodes.index(of: node) {
            floatingDelegate?.floatingScene?(self, startedRemovingOfFloatingNodeAtIndex: index)
        }
    }
    
    fileprivate func updateNodeState(_ node: SIFloatingNode!) {
        if let index = floatingNodes.index(of: node) {
            switch node.state {
            case .normal:
                if shouldSelectNodeAtIndex(index) {
                    if !allowMultipleSelection, let selectedIndex = indexOfSelectedNode() {
                        updateNodeState(floatingNodes[selectedIndex])
                    }
                    node.state = .selected
                    floatingDelegate?.floatingScene?(self, didSelectFloatingNodeAtIndex: index)
                }
            case .selected:
                if shouldDeselectNodeAtIndex(index) {
                    node.state = .normal
                    floatingDelegate?.floatingScene?(self, didDeselectFloatingNodeAtIndex: index)
                }
            case .removing:
                cancelRemovingNode(node)
            }
        }
    }
    
    // MARK: -
    // MARK: Configuration
    override open func addChild(_ node: SKNode) {
        if let child = node as? SIFloatingNode {
            configureNode(child)
            floatingNodes.append(child)
        }
        super.addChild(node)
    }
    
    fileprivate func configure() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        magneticField = SKFieldNode.radialGravityField()
        magneticField.region = SKRegion(radius: 10000)
        magneticField.minimumRadius = 10000
        magneticField.strength = 8000
        magneticField.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(magneticField)
    }
    
    fileprivate func configureNode(_ node: SIFloatingNode!) {
        if node.physicsBody == nil {
            var path: CGPath = CGMutablePath()
    
            if node.path != nil {
                path = node.path!
            }
            node.physicsBody = SKPhysicsBody(polygonFrom: path)
        }
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.mass = 0.3
        node.physicsBody?.friction = 0
        node.physicsBody?.linearDamping = 3
    }
    
    fileprivate func modeUpdated() {
        switch mode {
        case .normal, .moving:
            touchStartedTime = nil
            removingStartedTime = nil
            touchPoint = nil
        default: ()
        }
    }
    
    // MARK: -
    // MARK: Floating Delegate Helpers
    fileprivate func shouldRemoveNodeAtIndex(_ index: Int) -> Bool {
        if 0...floatingNodes.count - 1 ~= index {
            if let shouldRemove = floatingDelegate?.floatingScene?(self, shouldRemoveFloatingNodeAtIndex: index) {
                return shouldRemove
            }
            return true
        }
        return false
    }
    
    fileprivate func shouldSelectNodeAtIndex(_ index: Int) -> Bool {
        if let shouldSelect = floatingDelegate?.floatingScene?(self, shouldSelectFloatingNodeAtIndex: index) {
            return shouldSelect
        }
        return true
    }
    
    fileprivate func shouldDeselectNodeAtIndex(_ index: Int) -> Bool {
        if let shouldDeselect = floatingDelegate?.floatingScene?(self, shouldDeselectFloatingNodeAtIndex: index) {
            return shouldDeselect
        }
        return true
    }
}
