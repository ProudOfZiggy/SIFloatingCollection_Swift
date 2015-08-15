//
//  ViewController.swift
//  SIFloatingCollectionExample_Swift
//
//  Created by Neverland on 15.08.15.
//  Copyright (c) 2015 ProudOfZiggy. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {
    private var skView: SKView!
    private var floatingCollectionScene: BubblesScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView = SKView(frame: UIScreen.mainScreen().bounds)
        skView.backgroundColor = SKColor.whiteColor()
        view.addSubview(skView)
        
        floatingCollectionScene = BubblesScene(size: skView.bounds.size)
        let navbarHeight = CGRectGetHeight(navigationController!.navigationBar.frame)
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        let topOffset = navbarHeight + statusBarHeight
        floatingCollectionScene.topOffset = topOffset
        skView.presentScene(floatingCollectionScene)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Done,
            target: self,
            action: "commitSelection"
        )
        
        updateInterface()
    }
    
    private func updateInterface() {
        for i in 0..<20 {
            let node = BubbleTextNode.instantiate()
            floatingCollectionScene.addChild(node)
        }
    }
    
    dynamic private func commitSelection() {
        floatingCollectionScene.performCommitSelectionAnimation { () -> Void in
            self.updateInterface()
        }
    }
}

