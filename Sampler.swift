//
//  Sampler.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. All rights reserved.
//

import Cocoa

public class Sampler {
    let colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB)
    let bitmapInfo = CGBitmapInfo(
        rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).union(.ByteOrderDefault)

    private var imageBytes = [UInt8]()
    private(set) var imageWidth  = 0
    private(set) var imageHeight = 0
    
    private var _image: CGImage? = nil
    public  var  image: CGImage? {
        set {
            _image = newValue
            
            // Get image size information
            imageWidth   = CGImageGetWidth(_image)
            imageHeight  = CGImageGetHeight(_image)
            let rowSize  = 4 * imageWidth * 1 // 8-bit components

            // Allocate an array for the image if necessary
            if imageBytes.count <= rowSize * imageHeight {
                imageBytes   = [UInt8](count: rowSize * imageHeight, repeatedValue: 0)
            }
            
            // Create a new CGBitmapContext with the image size
            let tempContext = CGBitmapContextCreate(
                &imageBytes,
                imageWidth, imageHeight, sizeof(UInt8) * 8, rowSize,
                colorSpace, bitmapInfo.rawValue
            )
            if let context = tempContext {
                // Draw the image into the context
                CGContextDrawImage(
                    context,
                    CGRect(
                        origin: CGPoint(x: 0, y: 0),
                        size: CGSize(
                            width: imageWidth,
                            height: imageHeight
                        )
                    ),
                    _image
                )
                
                CGContextFlush(context)

            } else {
                print("Unable to create bitmap context in sampler")
            }
            
        }
        
        get {
            return _image
        }
    }
    
    public var grid: Grid
    
    public init(_ newGrid: Grid) {
        self.grid = newGrid
    }

    func getSample(atPoint point: NSPoint) -> NSColor? {
        guard Int(point.x) < imageWidth && Int(point.y) < imageHeight else {
            return nil
        }
        
        // The image coordinates are actually flipped.
        // Bitmap coordinates are 0,0 in top left, NSView is 0,0 in bottom left
        let coordinate: Int = (4 * Int(point.x)) + (4 * imageWidth * (imageHeight - Int(point.y)))
        
        return NSColor(
            deviceRed: CGFloat(imageBytes[0 + coordinate]) / 255.0,
            green:     CGFloat(imageBytes[1 + coordinate]) / 255.0,
            blue:      CGFloat(imageBytes[2 + coordinate]) / 255.0,
            alpha:     CGFloat(imageBytes[3 + coordinate]) / 255.0
        )
    }
    
    func getSample(inRect rect: NSRect) -> NSColor {
        var accumulator = (
            r: CGFloat(0.0),
            g: CGFloat(0.0),
            b: CGFloat(0.0),
            a: CGFloat(0.0))
        
        var samplePoints: CGFloat = 0
        for x in Int(rect.origin.x) ..< Int(rect.origin.x + rect.size.width) {
            for y in Int(rect.origin.y) ..< Int(rect.origin.y + rect.size.width) {
                if let sample = getSample(atPoint: NSPoint(x: x, y: y)) {
                    samplePoints += 1
                    accumulator.r += sample.redComponent
                    accumulator.g += sample.greenComponent
                    accumulator.b += sample.blueComponent
                    accumulator.a += sample.alphaComponent
                }
            }
        }
        
        accumulator.r = accumulator.r / samplePoints
        accumulator.g = accumulator.g / samplePoints
        accumulator.b = accumulator.b / samplePoints
        
        return NSColor(
            deviceRed: accumulator.r,
            green:     accumulator.g,
            blue:      accumulator.b,
            alpha:     accumulator.a
        )
    }
    
    func getSamples(withGrid grid: Grid) -> [NSColor] {
        let gridPoints = grid.getRects(10)
        return gridPoints.map { return getSample(inRect: $0) }
    }

}