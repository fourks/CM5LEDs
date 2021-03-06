//
//  AssetManager.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. See top level LICENSE file
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

    private(set) var width:  Int? = nil
    private(set) var height: Int? = nil
    
    private var track: AVAssetTrack? = nil
    
    var generating = false
    
    init(url: NSURL) {
        asset = AVURLAsset(URL: url)
        imageGenerator = AVAssetImageGenerator(asset: asset)
        duration  = CMTimeGetSeconds(asset.duration)
        
        track = asset.tracksWithMediaType(AVMediaTypeVideo).first
        if track != nil {
            width  = Int(track!.naturalSize.width)
            height = Int(track!.naturalSize.height)
            frameRate = track!.nominalFrameRate
        }
        
        // The tolerance is how much +/- we're willing to accept from the system
        let tolerance = CMTime(
            seconds: 1.0 / Double(frameRate) / 2.0,
            preferredTimescale: 600
        )
        
        // If we don't do this, it appears that the image generator will only give us
        // frames once every 1/2 second!? Perhaps these are the keyframes
        imageGenerator.requestedTimeToleranceAfter  = tolerance
        imageGenerator.requestedTimeToleranceBefore = tolerance
        
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
            
            if let image = imageOptional {
                block(actual, image)
            } else {
                self.generating = false
                self.cancelProcessing()
            }
        }
    }
}
