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
    private var _image: CGImage? = nil
    public  var image: CGImage? {
        set {
            _image = newValue
            self.needsDisplay = true
        }
        
        get { return _image }
    }
    
    public let grid = Grid()
    
    private enum Point {
        case TopLeft
        case TopRight
        case BottomLeft
        case BottomRight
    }
    
    private var draggedPoint: Point? = nil
    

}

//MARK: Drawing
extension AlignmentView {
    func drawImage(dirtyRect: NSRect) {
        if let img = image {
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
        drawClickTarget(grid.corners.tl)
        drawClickTarget(grid.corners.tr)
        drawClickTarget(grid.corners.bl)
        drawClickTarget(grid.corners.br)
        
        // The rest of the grid will be yellow
        NSColor.yellowColor().setStroke()
        
        for point in grid.points {
            // Skip the corners (they're click targets)
            if point == grid.corners.tl { continue }
            if point == grid.corners.tr { continue }
            if point == grid.corners.bl { continue }
            if point == grid.corners.br { continue }
            
            let circle = NSBezierPath(
                ovalInRect: NSRect(
                    x: point.x - 5.0,
                    y: point.y - 5.0,
                    width: 10.0,
                    height: 10.0
                )
            )
            
            circle.lineWidth = 1
            circle.stroke()
        }
    }
    
    override public func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        drawImage(dirtyRect)
        drawGrid(dirtyRect)
    }
}

//MARK: Interaction
extension AlignmentView {
    override public func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        
        let location = self.convertPoint(theEvent.locationInWindow, toView: nil)
        
        // Check whether any of the grid points are being dragged
        if location - grid.corners.tl <= 5.0 {
            Swift.print("Moving top left corner")
            draggedPoint = .TopLeft
        }
        if location - grid.corners.bl <= 5.0 {
            Swift.print("Moving bottom left corner")
            draggedPoint = .BottomLeft
        }
        if location - grid.corners.tr <= 5.0 {
            Swift.print("Moving top right corner")
            draggedPoint = .TopRight
        }
        if location - grid.corners.br <= 5.0 {
            Swift.print("Moving bottom right corner")
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