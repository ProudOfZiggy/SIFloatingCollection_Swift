//
//  ViewController.swift
//  Example
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {
    fileprivate var skView: SKView!
    fileprivate var floatingCollectionScene: BubblesScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        skView = SKView(frame: UIScreen.main.bounds)
        skView.backgroundColor = SKColor.white
        view.addSubview(skView)
        
        floatingCollectionScene = BubblesScene(size: skView.bounds.size)
        let navBarHeight = navigationController!.navigationBar.frame.height
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        floatingCollectionScene.topOffset = navBarHeight + statusBarHeight
        skView.presentScene(floatingCollectionScene)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(ViewController.commitSelection)
        )
        
        for _ in 0..<20 {
            let node = BubbleNode.instantiate()
            floatingCollectionScene.addChild(node!)
        }
    }
    
    dynamic fileprivate func commitSelection() {
        floatingCollectionScene.performCommitSelectionAnimation()
    }
}

