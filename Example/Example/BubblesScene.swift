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
    
    public static func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat.random() * (max - min) + min
    }
}

class BubblesScene: SIFloatingCollectionScene {
    var bottomOffset: CGFloat = 200
    var topOffset: CGFloat = 0
    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        configure()
    }
    
    private func configure() {
        backgroundColor = SKColor.whiteColor()
        scaleMode = .AspectFill
        allowMultipleSelection = false
        var bodyFrame = frame
        bodyFrame.size.width = CGFloat(magneticField.minimumRadius)
        bodyFrame.origin.x -= bodyFrame.size.width / 2
        bodyFrame.size.height = frame.size.height - bottomOffset
        bodyFrame.origin.y = frame.size.height - bodyFrame.size.height - topOffset
        physicsBody = SKPhysicsBody(edgeLoopFromRect: bodyFrame)
        magneticField.position = CGPointMake(frame.size.width / 2, frame.size.height / 2 + bottomOffset / 2 - topOffset)
    }
    
    override func addChild(node: SKNode) {
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
            node.position = CGPointMake(x, y)
        }
        super.addChild(node)
    }
    
    func performCommitSelectionAnimation() {
        physicsWorld.speed = 0
        let sortedNodes = sortedFloatingNodes()
        var actions: [SKAction] = []
        
        for node in sortedNodes {
            node.physicsBody = nil
            let action = actionForFloatingNode(node)
            actions.append(action)
        }
        runAction(SKAction.sequence(actions))
    }
    
    func throwNode(node: SKNode, toPoint: CGPoint, completion block: (() -> Void)!) {
        node.removeAllActions()
        let movingXAction = SKAction.moveToX(toPoint.x, duration: 0.2)
        let movingYAction = SKAction.moveToY(toPoint.y, duration: 0.4)
        let resize = SKAction.scaleTo(0.3, duration: 0.4)
        let throwAction = SKAction.group([movingXAction, movingYAction, resize])
        node.runAction(throwAction)
    }
    
    func sortedFloatingNodes() -> [SIFloatingNode]! {
        let sortedNodes = floatingNodes.sort { (node: SIFloatingNode, nextNode: SIFloatingNode) -> Bool in
            let distance = distanceBetweenPoints(node.position, secondPoint: self.magneticField.position)
            let nextDistance = distanceBetweenPoints(nextNode.position, secondPoint: self.magneticField.position)
            return distance < nextDistance && node.state != .Selected
        }
        return sortedNodes
    }
    
    func actionForFloatingNode(node: SIFloatingNode!) -> SKAction {
        let action = SKAction.runBlock({ () -> Void in
            if let index = self.floatingNodes.indexOf(node) {
                self.removeFloatinNodeAtIndex(index)
                if node.state == .Selected {
                    self.throwNode(
                        node,
                        toPoint: CGPointMake(self.size.width / 2, self.size.height + 40),
                        completion: {
                            node.removeFromParent()
                        }
                    )
                }
            }
        })
        return action
    }
}