//
//  AssetManager.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. All rights reserved.
//

import Foundation
import AVFoundation

extension NSLock {
    func protect(action: (Void) -> Void) {
        self.lock()
        action()
        self.unlock()
    }
}

class AssetManager {
    let asset: AVURLAsset
    let imageGenerator: AVAssetImageGenerator
    let duration: Double
    var frameRate: Float = 30
    let frames: [NSValue]

    var generating = false
    
    init(url: NSURL) {
        asset = AVURLAsset(URL: url)
        imageGenerator = AVAssetImageGenerator(asset: asset)
        duration  = CMTimeGetSeconds(asset.duration)
        
        // The tolerance is how much +/- we're willing to accept from the system
        let tolerance = CMTime(
            seconds: 1.0 / Double(frameRate) / 2.0,
            preferredTimescale: 600
        )
        // If we don't do this, it appears that the image generator will only give us
        // frames once every 1/2 second!?
        imageGenerator.requestedTimeToleranceAfter  = tolerance
        imageGenerator.requestedTimeToleranceBefore = tolerance
        
        if let rate = asset.tracksWithMediaType(AVMediaTypeVideo).first?.nominalFrameRate {
            frameRate = rate
        }
        
        var tempFrames = [NSValue]()
        var last = CMTime(seconds: 0.0, preferredTimescale: 600)
        repeat {
            last = CMTime(
                seconds: CMTimeGetSeconds(last) + (1.0 / Double(frameRate)),
                preferredTimescale: 600
            )
            tempFrames.append(NSValue(CMTime: last))
        } while CMTimeGetSeconds(last) < duration
        
        frames = tempFrames
    }
    
    func generateFrame(atTime: CMTime) -> CGImage? {
        if let image = try? imageGenerator.copyCGImageAtTime(atTime, actualTime: nil) {
            return image
        } else { return nil }
    }
    
    func cancelProcessing() {
        generating = false
        imageGenerator.cancelAllCGImageGeneration()
    }
    
    func processFrames(block: (CMTime, CGImage) -> Void) {
        generating = true
        
        // Ask for the images asynchronously
        imageGenerator.generateCGImagesAsynchronouslyForTimes(frames) { (
                requested: CMTime,
                imageOptional: CGImage?,
                actual: CMTime,
                result: AVAssetImageGeneratorResult,
                error: NSError?
            ) in
            
            guard result == .Succeeded else {
                self.generating = false
                self.cancelProcessing()
                return
            }

            guard error == nil else {
                self.generating = false
                self.cancelProcessing()
                return
            }
            
//            print("Difference in requested and actual time: \(CMTimeGetSeconds(requested) - CMTimeGetSeconds(actual))")
            
            if let image = imageOptional {
                block(actual, image)
            } else {
                self.generating = false
                self.cancelProcessing()
            }
        }
    }
}
