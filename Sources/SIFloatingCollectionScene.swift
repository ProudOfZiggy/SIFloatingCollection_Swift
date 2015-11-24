//
//  SIFloatingCollectionScene.swift
//  SIFloatingCollectionExample_Swift
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import SpriteKit

public func distanceBetweenPoints(firstPoint: CGPoint, secondPoint: CGPoint) -> CGFloat {
    return hypot(secondPoint.x - firstPoint.x, secondPoint.y - firstPoint.y)
}

@objc public protocol SIFloatingCollectionSceneDelegate {
    optional func floatingScene(scene: SIFloatingCollectionScene, shouldSelectFloatingNodeAtIndex index: Int) -> Bool
    optional func floatingScene(scene: SIFloatingCollectionScene, didSelectFloatingNodeAtIndex index: Int)
    
    optional func floatingScene(scene: SIFloatingCollectionScene, shouldDeselectFloatingNodeAtIndex index: Int) -> Bool
    optional func floatingScene(scene: SIFloatingCollectionScene, didDeselectFloatingNodeAtIndex index: Int)
    
    optional func floatingScene(scene: SIFloatingCollectionScene, startedRemovingOfFloatingNodeAtIndex index: Int)
    optional func floatingScene(scene: SIFloatingCollectionScene, canceledRemovingOfFloatingNodeAtIndex index: Int)
    
    optional func floatingScene(scene: SIFloatingCollectionScene, shouldRemoveFloatingNodeAtIndex index: Int) -> Bool
    optional func floatingScene(scene: SIFloatingCollectionScene, didRemoveFloatingNodeAtIndex index: Int)
}

public enum SIFloatingCollectionSceneMode {
    case Normal
    case Editing
    case Moving
}

public class SIFloatingCollectionScene: SKScene {
    private(set) public var magneticField = SKFieldNode.radialGravityField()
    private(set) var mode: SIFloatingCollectionSceneMode = .Normal {
        didSet {
            modeUpdated()
        }
    }
    private(set) public var floatingNodes: [SIFloatingNode] = []
    
    private var touchPoint: CGPoint?
    private var touchStartedTime: NSTimeInterval?
    private var removingStartedTime: NSTimeInterval?
    
    public var timeToStartRemove: NSTimeInterval = 0.7
    public var timeToRemove: NSTimeInterval = 2
    public var allowEditing = false
    public var allowMultipleSelection = true
    public var restrictedToBounds = true
    public var pushStrength: CGFloat = 10000
    public weak var floatingDelegate: SIFloatingCollectionSceneDelegate?
    
    override public func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        configure()
    }
    
    // MARK: -
    // MARK: Frame Updates
    //@todo refactoring
    override public func update(currentTime: NSTimeInterval) {
        let _ = floatingNodes.map { (node: SKNode) -> Void in
            let distanceFromCenter = distanceBetweenPoints(self.magneticField.position, secondPoint: node.position)
            node.physicsBody?.linearDamping = distanceFromCenter > 100 ? 2 : 2 + ((100 - distanceFromCenter) / 10)
        }
        
        if mode == .Moving || !allowEditing {
            return
        }
        
        if let tStartTime = touchStartedTime, tPoint = touchPoint {
            let dTime = currentTime - tStartTime
            if dTime >= timeToStartRemove {
                touchStartedTime = nil
                if let node = nodeAtPoint(tPoint) as? SIFloatingNode {
                    removingStartedTime = currentTime
                    startRemovingNode(node)
                }
            }
        } else if mode == .Editing, let tRemovingTime = removingStartedTime, tPoint = touchPoint {
            let dTime = currentTime - tRemovingTime
            if dTime >= timeToRemove {
                removingStartedTime = nil
                if let node = nodeAtPoint(tPoint) as? SIFloatingNode {
                    if let index = floatingNodes.indexOf(node) {
                        removeFloatinNodeAtIndex(index)
                    }
                }
            }
        }
    }
    
    // MARK: -
    // MARK: Touching Handlers
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first as UITouch? {
            touchPoint = touch.locationInNode(self)
            touchStartedTime = touch.timestamp
        }
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if mode == .Editing {
            return
        }
        
        if let touch = touches.first as UITouch? {
            let plin = touch.previousLocationInNode(self)
            let lin = touch.locationInNode(self)
            var dx = lin.x - plin.x
            var dy = lin.y - plin.y
            let b = sqrt(pow(lin.x, 2) + pow(lin.y, 2))
            dx = b == 0 ? 0 : (dx / b)
            dy = b == 0 ? 0 : (dy / b)
            
            if dx == 0 && dy == 0 {
                return
            } else if mode != .Moving {
                mode = .Moving
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
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if mode != .Moving, let touch = touchPoint {
            if let node = nodeAtPoint(touch) as? SIFloatingNode {
                updateNodeState(node)
            }
        }
        mode = .Normal
    }
    
    override public func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        mode = .Normal
    }
    
    // MARK: -
    // MARK: Nodes Manipulation
    private func cancelRemovingNode(node: SIFloatingNode!) {
        mode = .Normal
        node.physicsBody?.dynamic = true
        node.state = node.previousState
        if let index = floatingNodes.indexOf(node) {
            floatingDelegate?.floatingScene?(self, canceledRemovingOfFloatingNodeAtIndex: index)
        }
    }
    
    public func floatingNodeAtIndex(index: Int) -> SIFloatingNode? {
        if index < floatingNodes.count && index >= 0 {
            return floatingNodes[index]
        }
        return nil
    }
    
    public func indexOfSelectedNode() -> Int? {
        var index: Int?
        
        for (idx, node) in floatingNodes.enumerate() {
            if node.state == .Selected {
                index = idx
                break
            }
        }
        return index
    }
    
    public func indexesOfSelectedNodes() -> [Int]! {
        var indexes: [Int] = []
        
        for (idx, node) in floatingNodes.enumerate() {
            if node.state == .Selected {
                indexes.append(idx)
            }
        }
        return indexes
    }
    
    override public func nodeAtPoint(p: CGPoint) -> SKNode {
        var currentNode = super.nodeAtPoint(p)
        
        while !(currentNode.parent is SKScene) && !(currentNode is SIFloatingNode)
            && (currentNode.parent != nil) && !currentNode.userInteractionEnabled {
                currentNode = currentNode.parent!
        }
        return currentNode
    }
    
    public func removeFloatinNodeAtIndex(index: Int) {
        if shouldRemoveNodeAtIndex(index) {
            let node = floatingNodes[index]
            floatingNodes.removeAtIndex(index)
            node.removeFromParent()
            floatingDelegate?.floatingScene?(self, didRemoveFloatingNodeAtIndex: index)
        }
    }
    
    private func startRemovingNode(node: SIFloatingNode!) {
        mode = .Editing
        node.physicsBody?.dynamic = false
        node.state = .Removing
        if let index = floatingNodes.indexOf(node) {
            floatingDelegate?.floatingScene?(self, startedRemovingOfFloatingNodeAtIndex: index)
        }
    }
    
    private func updateNodeState(node: SIFloatingNode!) {
        if let index = floatingNodes.indexOf(node) {
            switch node.state {
            case .Normal:
                if shouldSelectNodeAtIndex(index) {
                    if !allowMultipleSelection, let selectedIndex = indexOfSelectedNode() {
                        updateNodeState(floatingNodes[selectedIndex])
                    }
                    node.state = .Selected
                    floatingDelegate?.floatingScene?(self, didSelectFloatingNodeAtIndex: index)
                }
            case .Selected:
                if shouldDeselectNodeAtIndex(index) {
                    node.state = .Normal
                    floatingDelegate?.floatingScene?(self, didDeselectFloatingNodeAtIndex: index)
                }
            case .Removing:
                cancelRemovingNode(node)
            }
        }
    }
    
    // MARK: -
    // MARK: Configuration
    override public func addChild(node: SKNode) {
        if let child = node as? SIFloatingNode {
            configureNode(child)
            floatingNodes.append(child)
        }
        super.addChild(node)
    }
    
    private func configure() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        magneticField = SKFieldNode.radialGravityField()
        magneticField.region = SKRegion(radius: 10000)
        magneticField.minimumRadius = 10000
        magneticField.strength = 8000
        magneticField.position = CGPointMake(size.width / 2, size.height / 2)
        addChild(magneticField)
    }
    
    private func configureNode(node: SIFloatingNode!) {
        if node.physicsBody == nil {
            var path: CGPath = CGPathCreateMutable()
    
            if node.path != nil {
                path = node.path!
            }
            node.physicsBody = SKPhysicsBody(polygonFromPath: path)
        }
        node.physicsBody?.dynamic = true
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.mass = 0.3
        node.physicsBody?.friction = 0
        node.physicsBody?.linearDamping = 3
    }
    
    private func modeUpdated() {
        switch mode {
        case .Normal, .Moving:
            touchStartedTime = nil
            removingStartedTime = nil
            touchPoint = nil
        default: ()
        }
    }
    
    // MARK: -
    // MARK: Floating Delegate Helpers
    private func shouldRemoveNodeAtIndex(index: Int) -> Bool {
        if 0...floatingNodes.count - 1 ~= index {
            if let shouldRemove = floatingDelegate?.floatingScene?(self, shouldRemoveFloatingNodeAtIndex: index) {
                return shouldRemove
            }
            return true
        }
        return false
    }
    
    private func shouldSelectNodeAtIndex(index: Int) -> Bool {
        if let shouldSelect = floatingDelegate?.floatingScene?(self, shouldSelectFloatingNodeAtIndex: index) {
            return shouldSelect
        }
        return true
    }
    
    private func shouldDeselectNodeAtIndex(index: Int) -> Bool {
        if let shouldDeselect = floatingDelegate?.floatingScene?(self, shouldDeselectFloatingNodeAtIndex: index) {
            return shouldDeselect
        }
        return true
    }
}
