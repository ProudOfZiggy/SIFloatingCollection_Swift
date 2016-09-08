//
//  SIFloatingNode.swift
//  SIFloatingCollectionExample_Swift
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import SpriteKit

public enum SIFloatingNodeState {
    case normal
    case selected
    case removing
}

open class SIFloatingNode: SKShapeNode {
    fileprivate(set) var previousState: SIFloatingNodeState = .normal
    fileprivate var _state: SIFloatingNodeState = .normal
    open var state: SIFloatingNodeState {
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
    
    open static let removingKey = "action.removing"
    open static let selectingKey = "action.selecting"
    open static let normalizeKey = "action.normalize"
    
    fileprivate func stateChaged() {
        var action: SKAction?
        var actionKey: String?
        
        switch state {
        case .normal:
            action = normalizeAnimation()
            actionKey = SIFloatingNode.normalizeKey
        case .selected:
            action = selectingAnimation()
            actionKey = SIFloatingNode.selectingKey
        case .removing:
            action = removingAnimation()
            actionKey = SIFloatingNode.removingKey
        }
        
        if let a = action, let ak = actionKey {
            run(a, withKey: ak)
        }
    }
    
    override open func removeFromParent() {
        if let action = removeAnimation() {
            run(action, completion: { () -> Void in
                super.removeFromParent()
            })
        } else {
            super.removeFromParent()
        }
    }
    
    // MARK: -
    // MARK: Animations
    open func selectingAnimation() -> SKAction? {return nil}
    open func normalizeAnimation() -> SKAction? {return nil}
    open func removeAnimation() -> SKAction? {return nil}
    open func removingAnimation() -> SKAction? {return nil}
}
