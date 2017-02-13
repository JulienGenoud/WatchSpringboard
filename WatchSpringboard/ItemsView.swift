//
//  ItemsView.swift
//  WatchSpringboard
//
//  Created by Joe Blau on 11/8/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

import UIKit

class ItemsView: UIView {
    
    var springboardView: SpringboardView = SpringboardView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        springboardView.frame = UIScreen.main.bounds
        
        var itemViews: [SpringboardItemView] = Array<SpringboardItemView>()
        let clipPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 60, height: 60).insetBy(dx: 0.5, dy: 0.5))
        
        for idx in 1..<100 {
            
            let itemView = SpringboardItemView()
            let image = UIImage(named: "item")
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: 60, height: 60), false, UIScreen.main.scale)
            clipPath.addClip()
            image?.draw(in: CGRect(x: 0, y: 0, width: 60, height: 60))
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            itemView.icon.image = renderedImage
            itemView.title = "Item \(idx)"
            itemViews += [itemView]
        }
        
        springboardView.itemViews = itemViews
        addSubview(springboardView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var statusFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        if self.window != nil {
            let statusBarFrame = UIApplication.shared.statusBarFrame
            statusFrame = self.window!.convert(statusBarFrame, to: self)
            
            var insets = springboardView.contentInset
            insets.top = statusFrame.size.height
            springboardView.contentInset = insets
        }
    }
    
    // MARK: - Actions
    
    func selectEmotion() {
        print("select")
    }
}
