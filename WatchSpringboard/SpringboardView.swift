//
//  SpringboardView.swift
//  WatchSpringboard
//
//  Created by Joe Blau on 11/1/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


func PointDistanceSquared(_ x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) -> CGFloat {
    return sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
}

func PointDistance(_ x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) -> CGFloat {
    return ((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
}

class SpringboardView: UIScrollView, UIScrollViewDelegate {
    
    let touchView: UIView! = UIView()
    let contentView: UIView! = UIView()
    var transformFactor: CGFloat!
    var lastFocusedViewIndex: UInt! = 0
    var zoomScaleCache: CGFloat!
    var minTransform: CGAffineTransform!
    var isMinZoomLevelDirty: Bool = true
    var isContentSizeDirty: Bool = true
    var contentSizeUnscaled: CGSize!
    var contentSizeExtra: CGSize!
    var centerOnEndDrag: Bool = true
    var centerOnEndDecelerate: Bool = true
    var minimumZoomLevelInteraction: CGFloat!
    var doubleTapGesture: UITapGestureRecognizer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override var bounds: CGRect {
        didSet {
            if bounds.size.equalTo(self.bounds.size) == false {
                setMinimumZoomLevelIsDirty()
            }
            super.bounds = bounds
        }
    }
    
    override var frame: CGRect {
        didSet {
            if frame.size.equalTo(self.bounds.size) == false {
                setMinimumZoomLevelIsDirty()
            }
            super.frame = frame
        }
    }
    
    var itemViews: [SpringboardItemView]! {
        willSet {
            if let views = itemViews {
                for view in views {
                    if view.isDescendant(of: self) {
                        view.removeFromSuperview()
                    }
                }
            }
        }
        
        didSet {
            for view in itemViews {
                contentView.addSubview(view)
            }
            setMinimumZoomLevelIsDirty()
        }
    }
    
    var itemDiameter: UInt! {
        didSet {
            setMinimumZoomLevelIsDirty()
        }
    }
    
    var itemPadding: UInt! {
        didSet {
            setMinimumZoomLevelIsDirty()
        }
    }
    
    var minimumItemScaling: CGFloat! {
        didSet {
            setNeedsLayout()
        }
    }
    
    func showAllContent(_ animated: Bool) {
        let contentRectInContentSpace = fullContentRectInContentSpace()
        lastFocusedViewIndex = closestIndexToPointInContent(rectCenter(contentRectInContentSpace))
        
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, options: [.layoutSubviews, .allowAnimatedContent, .beginFromCurrentState], animations: { () -> Void in
                self.zoom(to: contentRectInContentSpace, animated: false)
                self.layoutIfNeeded()
                }, completion: nil)
        } else {
            zoom(to: contentRectInContentSpace, animated: false)
        }
    }
    
    func indexOfItemClosestTo(_ point: CGPoint) -> UInt {
        return closestIndexToPointInContent(point)
    }
    
    func centerOn(_ index: UInt, zoomScale: CGFloat, animated: Bool) {
        lastFocusedViewIndex = index
        let view = itemViews[Int(index)]
        let centerContentSpace = view.center
        
        if zoomScale == self.zoomScale {
            let sizeInSelfSpace = self.bounds.size
            let centerInSelfSpace = pointInContentToSelf(centerContentSpace)
            let rectInSelfSpace = rectWithCenter(centerInSelfSpace, size: sizeInSelfSpace)
            scrollRectToVisible(rectInSelfSpace, animated: animated)
        } else {
            let rectInContentSpace = rectWithCenter(centerContentSpace, size: view.bounds.size)
            zoom(to: rectInContentSpace, animated: animated)
        }
    }
    
    func doIntroAnimation() {
        layoutIfNeeded()
        
        let size = self.bounds.size
        var idx: UInt = 0
        let minScale:CGFloat = 0.5
        let centerView = itemViews[Int(lastFocusedViewIndex)]
        let centerViewCenter = centerView.center
        for view in itemViews {
            let viewCenter = view.center
            view.alpha = 0
            let dx = viewCenter.x - centerViewCenter.x
            let dy = viewCenter.y - centerViewCenter.y
            let distance = (dx * dx - dy * dy)
            let factor = max(min(max(size.width, size.height) / distance, 1), 0)
            let scaleFactor: CGFloat = ((factor) * 0.8 + 0.2)
            let translateFactor: CGFloat = -0.9
            
            view.transform = CGAffineTransform(translationX: dx*translateFactor, y: dy * translateFactor).scaledBy(x: minScale*scaleFactor, y: minScale*scaleFactor)
            idx += 1
        }
        
        setNeedsLayout()
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            for view in self.itemViews {
                view.alpha = 1
            }
            self.layoutSubviews()
            }, completion: nil)
    }
    
    // MARK: - UITapGestureRecognizer
    
    func didZoomGesture(_ sender: UITapGestureRecognizer) {

        
        if zoomScale >= minimumZoomLevelInteraction && zoomScale != minimumZoomScale {
            showAllContent(true)
        } else {
            let positionInSelf = sender.location(in: self)
            let targetIndex = closestIndexToPointInContent(positionInSelf)
            print(targetIndex)
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                self.centerOn(targetIndex-1, zoomScale: 1, animated: false)
                self.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    // MARK: - Private Functions
    func initialize() {
        delaysContentTouches = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        
        self.itemDiameter = 68
        itemPadding = 48
        minimumItemScaling = 0.5
        
        transformFactor = 1
        zoomScaleCache = zoomScale
        minimumZoomLevelInteraction = 0.4
        
        addSubview(touchView)
        addSubview(contentView)
        
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(SpringboardView.didZoomGesture(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapGesture)
        
    }
    
    func pointInSelfToContent(_ point: CGPoint) -> CGPoint {
        let zoomScale = self.zoomScale
        return CGPoint(x: point.x/zoomScale, y: point.y/zoomScale)
    }
    
    func pointInContentToSelf(_ point: CGPoint) -> CGPoint {
        let zoomScale = self.zoomScale
        return CGPoint(x: point.x*zoomScale, y: point.y*zoomScale)
    }
    
    func sizeInSelfToContent(_ size: CGSize) -> CGSize {
        let zoomScale = self.zoomScale
        return CGSize(width: size.width/zoomScale, height: size.height/zoomScale)
    }
    
    func sizeInContentToSelf(_ size: CGSize) -> CGSize {
        let zoomScale = self.zoomScale
        return CGSize(width: size.width*zoomScale, height: size.height*zoomScale)
    }
    
    func rectCenter(_ rect: CGRect) -> CGPoint {
        return CGPoint(x: rect.origin.x+rect.size.width*0.5, y: rect.origin.y+rect.size.height*0.5)
    }
    
    func rectWithCenter(_ center: CGPoint, size: CGSize) -> CGRect {
        return CGRect(x: center.x-size.width*0.5, y: center.y-size.height*0.5, width: size.width, height: size.height)
    }
    
    func transformView(_ view: SpringboardItemView) {
        let size = self.bounds.size
        let zoomScale = zoomScaleCache
        let insets = self.contentInset
        
        var center = view.center
        let floatDiameter = CGFloat(itemDiameter)
        let floatPadding = CGFloat(itemPadding)
        var frame = self.convert(CGRect(x: view.center.x - floatDiameter/2, y: view.center.y - floatDiameter/2, width: floatDiameter, height: floatDiameter), from: view.superview)
        let contentOffset = self.contentOffset
        frame.origin.x -= contentOffset.x
        frame.origin.y -= contentOffset.y
        center = CGPoint(x: frame.origin.x+frame.size.width/2, y: frame.origin.y+frame.size.height/2)
        let padding = floatPadding * zoomScale! * 0.4
        var distanceToBorder: CGFloat = size.width
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        
        let distanceToBeOffset = floatDiameter * zoomScale! * (min(size.width, size.height)/320)
        let leftDistance = center.x - padding - insets.left
        if leftDistance < distanceToBeOffset {
            if leftDistance < distanceToBorder {
                distanceToBorder = leftDistance
            }
            xOffset = 1 - leftDistance / distanceToBeOffset
        }
        let topDistance = center.y - padding - insets.top
        if topDistance < distanceToBeOffset {
            if topDistance < distanceToBorder {
                distanceToBorder = topDistance
            }
            yOffset = 1 - topDistance / distanceToBeOffset
        }
        let rightDistance = size.width - padding - center.x - insets.right
        if rightDistance < distanceToBeOffset {
            if rightDistance < distanceToBorder {
                distanceToBorder = rightDistance
            }
            xOffset = -(1 - rightDistance / distanceToBeOffset)
        }
        let bottomDistance = size.height - padding - center.y - insets.bottom
        if bottomDistance < distanceToBeOffset {
            if bottomDistance < distanceToBorder {
                distanceToBorder = bottomDistance
            }
            yOffset = -(1 - bottomDistance / distanceToBeOffset)
        }
        
        distanceToBorder *= 2
        var usedScale: CGFloat!
        if distanceToBorder < distanceToBeOffset * 2 {
            if distanceToBorder < -(floatDiameter*2.5) {
                view.transform = minTransform
                usedScale = minimumItemScaling * zoomScale!
            } else {
                var rawScale = max(distanceToBorder / (distanceToBeOffset * 2), 0)
                rawScale = min(rawScale,1)
                rawScale = 1 - ((1-rawScale) * (1-rawScale))
                var scale = rawScale * (1 - minimumItemScaling) + minimumItemScaling
                
                xOffset = frame.size.width * 0.8 * (1 - rawScale) * xOffset
                yOffset = frame.size.width * 0.5 * (1 - rawScale) * yOffset
                
                var translationModifier = min(distanceToBorder / floatDiameter+2.5, 1)
                
                scale = max(min(scale * transformFactor + (1 - transformFactor), 1), 0)
                translationModifier = min(translationModifier * transformFactor, 1)
                view.transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset * translationModifier, y: yOffset * translationModifier)
                
                usedScale = scale * zoomScale!
            }
        } else {
            view.transform = CGAffineTransform.identity
            usedScale = zoomScale
        }
        if self.isDragging || self.isZooming {
            view.setScale(usedScale, animated: true)
        } else {
            view.scale = usedScale
        }
    }
    
    func setMinimumZoomLevelIsDirty() {
        isMinZoomLevelDirty = true
        isContentSizeDirty = true
        setNeedsLayout()
    }
    
    func closestIndexToPointInSelf(_ pointInSelf: CGPoint) -> UInt {
        let pointInContent = self.pointInContentToSelf(pointInSelf)
        return closestIndexToPointInContent(pointInContent)
    }
    
    func closestIndexToPointInContent(_ pointInContent: CGPoint) -> UInt {
        var distance = CGFloat(FLT_MAX)
        var index = lastFocusedViewIndex
        for (idx, view) in itemViews.enumerated() {
            
            let center = CGPoint(x: view.center.x / UIScreen.main.scale, y: view.center.y / UIScreen.main.scale)
            let potentialDistance = PointDistance(center.x, y1: center.y, x2: pointInContent.x, y2: pointInContent.y)
            
            if (potentialDistance < distance) {
                distance = potentialDistance
                index = UInt(idx)
            }
        }
        return index!
    }
    
    func centerOnClosestToScreenCenterAnimated(_ animated: Bool) {
        let sizeInSelf = self.bounds.size
        let centerInSelf = CGPoint(x: sizeInSelf.width * 0.5, y: sizeInSelf.height * 0.5)
        let closestIndex = self.closestIndexToPointInSelf(centerInSelf)
        self.centerOn(closestIndex, zoomScale: zoomScale, animated: animated)
    }
    
    func fullContentRectInContentSpace() -> CGRect {
        return CGRect(x: self.contentSizeExtra.width*0.5,
            y: contentSizeExtra.height*0.5,
            width: contentSizeUnscaled.width - contentSizeExtra.width,
            height: contentSizeUnscaled.height - contentSizeExtra.height)
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let size = self.bounds.size
        let zoomScale = self.zoomScale
        
        var proposedTargetCenter = CGPoint(x: targetContentOffset.pointee.x+size.width/2, y: targetContentOffset.pointee.y+size.height/2)
        proposedTargetCenter.x /= zoomScale
        proposedTargetCenter.y /= zoomScale
        
        lastFocusedViewIndex = closestIndexToPointInContent(proposedTargetCenter)
        let view = itemViews[Int(lastFocusedViewIndex)]
        let idealTargetCenter = view.center
        
        let idealTargetOffset = CGPoint(x: idealTargetCenter.x-size.width/2/zoomScale,
            y: idealTargetCenter.y-size.height/2/zoomScale)
        
        let correctedTargetOffset = CGPoint(x: idealTargetOffset.x*zoomScale,
            y: idealTargetOffset.y*zoomScale)
        
        var currentCenter = CGPoint(x: self.contentOffset.x+size.width/2, y: self.contentOffset.y+size.height/2)
        currentCenter.x /= zoomScale
        currentCenter.y /= zoomScale
        
        var contentCenter = contentView.center
        contentCenter.x /= zoomScale
        contentCenter.y /= zoomScale
        
        let contentSizeNoExtras = CGSize(width: contentSizeUnscaled.width-contentSizeExtra.width,
            height: contentSizeUnscaled.height-contentSizeExtra.height)
        let contentFrame = CGRect(x: contentCenter.x-contentSizeNoExtras.width*0.5, y: contentCenter.y-contentSizeNoExtras.height*0.5, width: contentSizeNoExtras.width, height: contentSizeNoExtras.height)
        
        if contentFrame.contains(proposedTargetCenter) {
            targetContentOffset.pointee = correctedTargetOffset
        } else {
            if contentFrame.contains(currentCenter) {
                let ourPriority: CGFloat = 0.8
                
                targetContentOffset.pointee = CGPoint(
                    x: targetContentOffset.pointee.x*(1.0-ourPriority)+correctedTargetOffset.x*ourPriority,
                    y: targetContentOffset.pointee.y*(1.0-ourPriority)+correctedTargetOffset.y*ourPriority)
                centerOnEndDecelerate = true
            } else {
                targetContentOffset.pointee = contentOffset
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if centerOnEndDrag {
            centerOnEndDrag = false
            centerOn(lastFocusedViewIndex, zoomScale: zoomScale, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if centerOnEndDecelerate {
            centerOnEndDecelerate = false
            centerOn(lastFocusedViewIndex, zoomScale: zoomScale, animated: true)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomScaleCache = zoomScale
    }
    
    // MARK: UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        let size = bounds.size
        let insets = contentInset
        
        
        let items = min(size.width,size.height) / max(size.width,size.height) * sqrt(CGFloat(itemViews.count))
        var itemsPerLine = ceil(items)
        
        if itemsPerLine.truncatingRemainder(dividingBy: 2) == 0 {
            itemsPerLine += 1
        }
        let lines = ceil(CGFloat(itemViews.count)/itemsPerLine)
        var newMinimumZoomScale: CGFloat = 0
        
        let floatDiameter = CGFloat(itemDiameter)
        let floatPadding = CGFloat(itemPadding)
        if isContentSizeDirty {
            contentSizeUnscaled = CGSize(width: itemsPerLine*floatDiameter+(itemsPerLine+1)*floatPadding+(floatDiameter+floatPadding)/2, height: lines*floatDiameter+(2)*floatPadding)
            
            newMinimumZoomScale = min((size.width-insets.left-insets.right)/contentSizeUnscaled.width,
                (size.height-insets.top-insets.bottom)/contentSizeUnscaled.height)
            
            contentSizeExtra = CGSize(width: (size.width-floatDiameter*0.5)/newMinimumZoomScale,
                height: (size.height-floatDiameter*0.5)/newMinimumZoomScale)
            
            contentSizeUnscaled.width += contentSizeExtra.width
            contentSizeUnscaled.height += contentSizeExtra.height
            contentView.bounds = CGRect(x: 0, y: 0, width: contentSizeUnscaled.width, height: contentSizeUnscaled.height)
        }
        if isMinZoomLevelDirty {
            minimumZoomScale = newMinimumZoomScale
            let newZoom: CGFloat = max(zoomScale, newMinimumZoomScale)
            if newZoom != zoomScaleCache || true {
                zoomScale = newZoom
                zoomScaleCache = newZoom
                
                contentView.center = CGPoint(x: contentSizeUnscaled.width*0.5*newZoom, y: contentSizeUnscaled.height*0.5*newZoom)
                contentSize = CGSize(width: contentSizeUnscaled.width*newZoom, height: contentSizeUnscaled.height*newZoom)
            }
        }
        if isContentSizeDirty {
            var idx: UInt = 0
            for view in itemViews {
                view.bounds = CGRect(x: 0, y: 0, width: floatDiameter, height: floatDiameter)
                
                
                var line: UInt = UInt(CGFloat(idx)/itemsPerLine)
                var indexInLine: UInt = UInt(CGFloat(idx).truncatingRemainder(dividingBy: itemsPerLine))
                
                if idx == 0 {
                    line = UInt(CGFloat(itemViews.count)/itemsPerLine/2)
                    indexInLine = UInt(itemsPerLine/2)
                } else {
                    if line == UInt(CGFloat(itemViews.count)/itemsPerLine/2) && indexInLine == UInt(itemsPerLine/2) {
                        line = 0
                        indexInLine = 0
                    }
                }
                
                var lineOffset: UInt = 0
                if line%2 == 1 {
                    lineOffset = (itemDiameter+itemPadding) / 2
                }
                
                let floatLine = CGFloat(line)
                let floatLineOffset = CGFloat(lineOffset)
                let floatIndexInLine = CGFloat(indexInLine)
                
                let posX: CGFloat = contentSizeExtra.width*0.5+floatPadding+floatLineOffset+floatIndexInLine*(floatDiameter + floatPadding)+floatDiameter/2
                let posY: CGFloat = contentSizeExtra.height*0.5+floatPadding+floatLine*(floatDiameter)+floatDiameter/2
                
                view.center = CGPoint(x: posX, y: posY)
                idx += 1
            }
            isContentSizeDirty = false
        }
        if isMinZoomLevelDirty {
            if lastFocusedViewIndex <= UInt(itemViews.count) {
                centerOn(lastFocusedViewIndex, zoomScale: zoomScaleCache, animated: false)
                isMinZoomLevelDirty = false
            }
        }
        
        zoomScaleCache = self.zoomScale
        touchView.bounds = CGRect(x: 0, y: 0, width: (contentSizeUnscaled.width - contentSizeExtra.width) * zoomScaleCache, height: (contentSizeUnscaled.height - contentSizeExtra.height) * zoomScaleCache)
        touchView.center = CGPoint(x: contentSizeUnscaled.width * 0.5 * zoomScaleCache, y: contentSizeUnscaled.height * 0.5 * zoomScaleCache)
        
        let scale = min(minimumItemScaling * transformFactor + (1 - transformFactor), 1)
        minTransform = CGAffineTransform(scaleX: scale, y: scale)
        for view in itemViews {
            transformView(view)
        }
    }
    
    

    
    
    
}
