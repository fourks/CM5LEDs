//
//  Grid.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. All rights reserved.
//

import Foundation

public class Grid {
    var divisions = (x: 16, y: 32)
    var _corners = (
        bl: NSPoint(x:  20.0, y:  20.0),
        br: NSPoint(x: 440.0, y:  20.0),
        tr: NSPoint(x: 440.0, y: 600.0),
        tl: NSPoint(x:  20.0, y: 600.0)
    )
    
    var corners: (bl: NSPoint, br: NSPoint, tr: NSPoint, tl: NSPoint) {
        set {
            _corners = newValue
            _points = nil
        }
        
        get {
            return _corners
        }
    }

    var _points: [NSPoint]? = nil
    
    var points: [NSPoint] {
        get {
            if let _points = _points { return _points }
            else { _points = [NSPoint]() }
                
            // The grid is made up of two linear interpolations.  The vertical sides
            // are interpolated from the corners, and along those lines, the
            // horizontal lines are evenly spaced.  Along those lines, the points are
            // evenly spaced.  If the image is severely distorted from forshortening
            // this will produce a poor solution.
            
            // Delta1 x and y are the changes in X and Y from the left vertical line
            // Delta2 x and y are the changes from the right vertical line
            let delta1 = (
                x: corners.tl.x - corners.bl.x,
                y: corners.tl.y - corners.bl.y
            )
            
            let delta2 = (
                x: corners.tr.x - corners.br.x,
                y: corners.tr.y - corners.br.y
            )
            
            for y in 0..<divisions.y {
                // Draw lines from bottom to top, left to right
                let line = (
                    start: NSPoint(
                        x: corners.bl.x + CGFloat(y) * delta1.x / CGFloat(divisions.y - 1),
                        y: corners.bl.y + CGFloat(y) * delta1.y / CGFloat(divisions.y - 1)),
                    end: NSPoint(
                        x: corners.br.x + CGFloat(y) * delta2.x / CGFloat(divisions.y - 1),
                        y: corners.br.y + CGFloat(y) * delta2.y / CGFloat(divisions.y - 1))
                )
                
                // Draw little circles at each point
                for x in 0..<divisions.x {
                    
                    let delta = (
                        x: line.end.x - line.start.x,
                        y: line.end.y - line.start.y
                    )
                    
                    _points!.append(NSPoint(
                        x: line.start.x + CGFloat(x) * delta.x / CGFloat(divisions.x - 1),
                        y: line.start.y + CGFloat(x) * delta.y / CGFloat(divisions.x - 1)
                    ))
                }
            }
            
            return _points!
        }
    }
    
    func getRects(size: Double) -> [NSRect] {
        return points.map({ (point: CGPoint) -> NSRect in
            return NSRect(origin: point, size: CGSize(width: size, height: size))
        })
    }
}