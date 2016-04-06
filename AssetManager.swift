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
    let frames: [NSValue]

    var generating = false
    
    init(url: NSURL) {
        asset = AVURLAsset(URL: url)
        imageGenerator = AVAssetImageGenerator(asset: asset)
        duration = CMTimeGetSeconds(asset.duration)
        
        var tempFrames = [NSValue]()
        var last = CMTime(seconds: 0.0, preferredTimescale: 2992)
        repeat {
            last = CMTime(
                seconds: CMTimeGetSeconds(last) + (1 / 29.92),
                preferredTimescale: 2992
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
