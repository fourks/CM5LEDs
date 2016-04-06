//
//  Sampler.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. All rights reserved.
//

import Cocoa

public struct Sampler {
    func getSamples(inImage image: CGImage, withGrid grid: Grid) -> [NSColor] {
        // CGBitmapContext apparently only deals with alpha colors
        let bitmapSize = 4 * 8 * 480 * 640
//        var data = [UInt8](count: bitmapSize, repeatedValue: 0)
        let colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).union(.ByteOrderDefault)
        let bitmapContext = CGBitmapContextCreate(nil, 480, 640, 8, 4 * 480, colorSpace, bitmapInfo.rawValue)
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, 480, 640), image)
        CGContextFlush(bitmapContext)
        let pointer = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(bitmapContext))
        
        // Go through each region and get the average within the rect
        var output = [NSColor]()
        for rect in grid.getRects(5) {
            let currentComponent = pointer
            var accumulator = (
                r: CGFloat(0.0),
                g: CGFloat(0.0),
                b: CGFloat(0.0))
            
            
            for x in Int(rect.origin.x) ..< Int(rect.origin.x + rect.size.width) {
                for y in Int(rect.origin.y) ..< Int(rect.origin.y + rect.size.width) {
                    accumulator.r += CGFloat(data[0 + (4 * x) + (4 * Int(rect.size.width) * y)])
                    accumulator.g += CGFloat(data[1 + (4 * x) + (4 * Int(rect.size.width) * y)])
                    accumulator.b += CGFloat(data[2 + (4 * x) + (4 * Int(rect.size.width) * y)])
                }
            }
            
            accumulator.r = accumulator.r / (rect.size.height * rect.size.width)
            accumulator.g = accumulator.g / (rect.size.height * rect.size.width)
            accumulator.b = accumulator.b / (rect.size.height * rect.size.width)
            
            output.append(NSColor(
                calibratedRed: accumulator.r,
                green: accumulator.g,
                blue: accumulator.b,
                alpha: 1))
        }
        
        var accumulator = (
            r: CGFloat(0.0),
            g: CGFloat(0.0),
            b: CGFloat(0.0))

        for color in output {
            accumulator.r += color.redComponent
            accumulator.g += color.greenComponent
            accumulator.b += color.blueComponent
        }
        
        accumulator.r = accumulator.r / CGFloat(grid.points.count)
        accumulator.g = accumulator.g / CGFloat(grid.points.count)
        accumulator.b = accumulator.b / CGFloat(grid.points.count)
        print("Average color for frame: (\(accumulator.r),\(accumulator.g),\(accumulator.b))")
        
        return output
    }

}