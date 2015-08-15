//
//  SIFloatingNode.swift
//  SIFloatingCollectionExample_Swift
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import SpriteKit

enum SIFloatingNodeState {
    case Normal
    case Selected
    case Removing
}

class SIFloatingNode: SKShapeNode {
    private(set) var previousState: SIFloatingNodeState = .Normal
    private var _state: SIFloatingNodeState = .Normal
    var state: SIFloatingNodeState {
        get {
            return _state
        }
        set {
            if _state != newValue {
                previousState = _state
                _state = newValue
                stateChaged()
            }
        }
    }
    
    static let removingKey = "action.removing"
    static let selectingKey = "action.selecting"
    static let normalizeKey = "action.normalize"
    
    private func stateChaged() {
        var action: SKAction?
        var actionKey: String?
        
        switch state {
        case .Normal:
            action = normalizeAnimation()
            actionKey = SIFloatingNode.normalizeKey
        case .Selected:
            action = selectingAnimation()
            actionKey = SIFloatingNode.selectingKey
        case .Removing:
            action = removingAnimation()
            actionKey = SIFloatingNode.removingKey
        }
        
        if let a = action, ak = actionKey {
            runAction(a, withKey: ak)
        }
    }
    
    override func removeFromParent() {
        if let action = removeAnimation() {
            runAction(action, completion: { () -> Void in
                super.removeFromParent()
            })
        } else {
            super.removeFromParent()
        }
    }
    
    // MARK: -
    // MARK: Animations
    func selectingAnimation() -> SKAction? {return nil}
    func normalizeAnimation() -> SKAction? {return nil}
    func removeAnimation() -> SKAction? {return nil}
    func removingAnimation() -> SKAction? {return nil}
}
