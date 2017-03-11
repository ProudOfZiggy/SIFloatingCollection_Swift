//
//  BubblesScene.swift
//  Example
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import SpriteKit

extension CGFloat {
    
    public static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    public static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat.random() * (max - min) + min
    }
}

class BubblesScene: SIFloatingCollectionScene {
    var bottomOffset: CGFloat = 200
    var topOffset: CGFloat = 0
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        configure()
    }
    
    fileprivate func configure() {
        backgroundColor = SKColor.white
        scaleMode = .aspectFill
        allowMultipleSelection = false
        allowEditing = true
        var bodyFrame = frame
        bodyFrame.size.width = CGFloat(magneticField.minimumRadius)
        bodyFrame.origin.x -= bodyFrame.size.width / 2
        bodyFrame.size.height = frame.size.height - bottomOffset
        bodyFrame.origin.y = frame.size.height - bodyFrame.size.height - topOffset
        physicsBody = SKPhysicsBody(edgeLoopFrom: bodyFrame)
        magneticField.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2 + bottomOffset / 2 - topOffset)
    }
    
    override func addChild(_ node: SKNode) {
        if node is BubbleNode {
            var x = CGFloat.random(min: -bottomOffset, max: -node.frame.size.width)
            let y = CGFloat.random(
                min: frame.size.height - bottomOffset - node.frame.size.height,
                max: frame.size.height - topOffset - node.frame.size.height
            )
            
            if floatingNodes.count % 2 == 0 || floatingNodes.isEmpty {
                x = CGFloat.random(
                    min: frame.size.width + node.frame.size.width,
                    max: frame.size.width + bottomOffset
                )
            }
            node.position = CGPoint(x: x, y: y)
        }
        super.addChild(node)
    }
    
    func performCommitSelectionAnimation() {
        let currentPhysicsSpeed = physicsWorld.speed
        physicsWorld.speed = 0
        let sortedNodes = sortedFloatingNodes()
        var actions: [SKAction] = []
        
        for node in sortedNodes {
            node.physicsBody = nil
            let action = actionForFloatingNode(node)
            actions.append(action)
        }
        run(SKAction.sequence(actions)) { [weak self] in
            self?.physicsWorld.speed = currentPhysicsSpeed
        }
    }

    func sortedFloatingNodes() -> [SIFloatingNode] {
        return floatingNodes.sorted { (node: SIFloatingNode, nextNode: SIFloatingNode) -> Bool in
            let distance = node.position.distance(from: magneticField.position)
            let nextDistance = nextNode.position.distance(from: magneticField.position)
            return distance < nextDistance && node.state != .selected
        }
    }
    
    func actionForFloatingNode(_ node: SIFloatingNode!) -> SKAction {
        let action = SKAction.run { [unowned self] () -> Void in
            if let index = self.floatingNodes.index(of: node) {
                self.removeFloatingNode(at: index)
                
                if node.state == .selected {
                    let destinationPoint = CGPoint(x: self.size.width / 2, y: self.size.height + 40)
                    (node as? BubbleNode)?.throw(to: destinationPoint) {
                        node.removeFromParent()
                    }
                }
            }
        }
        return action
    }
}
