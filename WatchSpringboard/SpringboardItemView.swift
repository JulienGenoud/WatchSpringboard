//
//  SpringboardItemView.swift
//  WatchSpringboard
//
//  Created by Joe Blau on 11/1/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

import UIKit

class SpringboardItemView: UIView {
    
    let kSpringboardItemViewSmallThreshold: CGFloat = 0.75
    let icon: UIImageView = UIImageView()
    let label: UILabel = UILabel()
    
    var visualEffectView: UIView?
    var visualEffectMaskView: UIImageView?
    
    var scale: CGFloat! {
        didSet {
            self.setScale(scale, animated: false)
        }
    }
    
    var title: String! {
        didSet {
            label.text = title
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        scale = 1
        label.isOpaque = false
        label.backgroundColor = nil
        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        addSubview(label)
        addSubview(icon)
    }
    
    func setScale(_ scale: CGFloat, animated: Bool) {
        if self.scale != scale {
            let wasSmall = self.scale < kSpringboardItemViewSmallThreshold
            self.scale = scale
            setNeedsLayout()
            if (self.scale < kSpringboardItemViewSmallThreshold) != wasSmall {
                if animated {
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        self.layoutIfNeeded()
                        self.label.alpha = self.scale < self.kSpringboardItemViewSmallThreshold ? 0 : 1
                    })
                } else {
                    self.label.alpha = self.scale < self.kSpringboardItemViewSmallThreshold ? 0 : 1
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size = self.bounds.size
        
        icon.center = CGPoint(x: size.width*0.5, y: size.height*0.5)
        icon.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        if let vev = visualEffectView {
            vev.center = icon.center
            vev.bounds = icon.bounds
        }
        if let vemv = visualEffectMaskView {
            vemv.center = icon.center
            vemv.bounds = icon.bounds
        }
        label.sizeToFit()
        label.center = CGPoint(x: size.width*0.5, y: size.height+4)
        
        let scale = 60/size.width
        icon.transform = CGAffineTransform(scaleX: scale, y: scale)
        if let vev = visualEffectView {
            vev.transform = icon.transform
        }
    }
}
