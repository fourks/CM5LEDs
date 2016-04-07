//
//  AlignmentView.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. All rights reserved.
//

import Cocoa

func -(lhs: NSPoint, rhs: NSPoint) -> Double {
    // Using pythagoras, get the distance between the points
    let x = lhs.x - rhs.x
    let y = lhs.y - rhs.y
    let hypSq = x * x + y * y
    return sqrt(Double(hypSq))
}

public class AlignmentView: NSView {
    public var sampler: Sampler? = nil
    public let grid = Grid()
    
    private enum Point {
        case TopLeft
        case TopRight
        case BottomLeft
        case BottomRight
    }
    
    private var draggedPoint: Point? = nil
    
    private var animating = false
}

//MARK: Drawing
extension AlignmentView {
    func startAnimating() {
        animating    = true
        needsDisplay = true
    }
    
    func stopAnimating() {
        animating = false
    }
    
    func drawImage(dirtyRect: NSRect) {
        if let img = sampler?.image {
            let nsImage = NSImage(CGImage: img, size: NSSize(width: 480, height: 640))
            nsImage.drawInRect(self.bounds)
        }
            
        // If the is no image, draw a checkerboard
        else {
            // Light grey background
            NSColor.lightGrayColor()
            let backgroundPath = NSBezierPath(rect: self.bounds)
            backgroundPath.fill()
            
            // Dark grey squares
            NSColor.darkGrayColor()
            for x in 0 ..< Int(self.bounds.width / 10) {
                for y in 0 ..< Int(self.bounds.height / 10) {
                    let squarePath = NSBezierPath(rect: NSRect(
                        x: Double(x) * 20.0,
                        y: Double(y) * 20.0,
                        width: 10.0,
                        height: 10.0
                        ))
                    squarePath.fill()
                }
            }
        }
    }
    
    func drawClickTarget(at: NSPoint) {
        // Draw prominant targets for the corners
        NSColor.whiteColor().setStroke()
        NSColor.blackColor().setFill()
        
        let circle = NSBezierPath(ovalInRect: NSRect(
            x: at.x - 5.0, y: at.y - 5.0, width: 10.0, height: 10.0)
        )
        
        circle.lineWidth = 1
        circle.stroke()
    }
    
    
    func drawGrid(dirtyRect: NSRect) {
        NSColor.yellowColor().setStroke()
        
        for rect in grid.getRects(10) {
            
            let circle = NSBezierPath(ovalInRect: rect)
            
            circle.lineWidth = 1
            circle.stroke()
        }
        
        drawClickTarget(grid.corners.tl)
        drawClickTarget(grid.corners.tr)
        drawClickTarget(grid.corners.bl)
        drawClickTarget(grid.corners.br)
    }
    
    override public func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        if let context = NSGraphicsContext.currentContext()?.CGContext,
           let sampler = self.sampler {
            CGContextDrawImage(context, CGRectMake(0, 0, 480, 640), sampler.image)
            CGContextFlush(context)
        }
        
//        drawImage(dirtyRect)
        drawGrid(dirtyRect)
        
        if animating {
            dispatch_async(dispatch_get_main_queue()) {
                self.needsDisplay = true
            }
        }
    }
}

//MARK: Interaction
extension AlignmentView {
    override public func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        
        let location = self.convertPoint(theEvent.locationInWindow, toView: nil)
        
        // Get the value of the image under the mouse pointer
        if let sampler = sampler {
            let color = sampler.getSample(atPoint: location)
            Swift.print(color)
        }

        // Check whether any of the grid points are being dragged
        if location - grid.corners.tl <= 5.0 {
            draggedPoint = .TopLeft
        }
        if location - grid.corners.bl <= 5.0 {
            draggedPoint = .BottomLeft
        }
        if location - grid.corners.tr <= 5.0 {
            draggedPoint = .TopRight
        }
        if location - grid.corners.br <= 5.0 {
            draggedPoint = .BottomRight
        }
    }
    
    override public func mouseDragged(theEvent: NSEvent) {
        super.mouseDragged(theEvent)
        
        guard draggedPoint != nil else { return }
        
        switch draggedPoint! {
        case .TopLeft:
            grid.corners.tl.x += theEvent.deltaX
            grid.corners.tl.y -= theEvent.deltaY
            self.needsDisplay = true
        case .TopRight:
            grid.corners.tr.x += theEvent.deltaX
            grid.corners.tr.y -= theEvent.deltaY
            self.needsDisplay = true
        case .BottomLeft:
            grid.corners.bl.x += theEvent.deltaX
            grid.corners.bl.y -= theEvent.deltaY
            self.needsDisplay = true
        case .BottomRight:
            grid.corners.br.x += theEvent.deltaX
            grid.corners.br.y -= theEvent.deltaY
            self.needsDisplay = true
        }
    }
    
    override public func mouseUp(theEvent: NSEvent) {
        super.mouseUp(theEvent)
        draggedPoint = nil
    }
    
    override public func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)
        draggedPoint = nil
    }
}