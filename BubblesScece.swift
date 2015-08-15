//
//  BubblesScece.swift
//  SIFloatingCollectionExample_Swift
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import SpriteKit

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
        var bodyFrame = frame
        bodyFrame.size.width = CGFloat(magneticField.minimumRadius)
        bodyFrame.origin.x -= bodyFrame.size.width / 2
        bodyFrame.size.height = frame.size.height - bottomOffset
        bodyFrame.origin.y = frame.size.height - bodyFrame.size.height - topOffset
        physicsBody = SKPhysicsBody(edgeLoopFromRect: bodyFrame)
        magneticField.position = CGPointMake(frame.size.width / 2, frame.size.height / 2 + bottomOffset / 2 - topOffset)
    }
    
    override func addChild(node: SKNode) {
        if node is BubbleTextNode {
            var x = CGFloat.random(min: -bottomOffset, max: -node.frame.size.width)
            var y = CGFloat.random(
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
    
    func performCommitSelectionAnimation(#completion: (() -> Void)?) {
        physicsWorld.speed = 0
        var sortedNodes = sortedFloatingNodes()
        var actions: [SKAction] = []
        
        for node in sortedNodes {
            node.physicsBody = nil
            let action = actionForFloatingNode(node)
            actions.append(action)
        }
        var localCompletion: () -> Void = {
            self.physicsWorld.speed = 1
            println(self.floatingNodes.count)
            if let _completion = completion {
                _completion()
            }
        }
        runAction(SKAction.sequence(actions), completion: localCompletion)
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
        var sortedNodes = floatingNodes.sorted { (node: SIFloatingNode, nextNode: SIFloatingNode) -> Bool in
            let distance = distanceBetweenPoints(node.position, self.magneticField.position)
            let nextDistance = distanceBetweenPoints(nextNode.position, self.magneticField.position)
            return distance < nextDistance && node.state != .Selected
        }
        return sortedNodes
    }
    
    func actionForFloatingNode(node: SIFloatingNode!) -> SKAction {
        let action = SKAction.runBlock({ () -> Void in
            if let index = find(self.floatingNodes, node) {
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