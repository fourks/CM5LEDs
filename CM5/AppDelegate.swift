//
//  AppDelegate.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. All rights reserved.
//

import Cocoa
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var viewer: AlignmentView!

    var manager: AssetManager? = nil
    let sampler = Sampler()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        manager = AssetManager(url: NSURL(fileURLWithPath: "/Users/wdillon/Desktop/CM5/CM5/CM5-small.mov"))
        viewer.image = manager?.generateFrame(CMTime(seconds: 0, preferredTimescale: 1))
    }

    var histogram = [Float](count: 256, repeatedValue: 0)
    var frameCount = 0
    @IBAction func run(sender: AnyObject?) {
        frameCount = 0
        histogram = [Float](count: 265, repeatedValue: 0)
        manager?.processFrames { (time: CMTime, image: CGImage) in
            
            dispatch_async(dispatch_get_main_queue()) {
                self.viewer.image = image
            }
            
            self.frameCount += 1
            let samples = self.sampler.getSamples(inImage: image, withGrid: self.viewer.grid)
            
            // Accumulate the value of each sample to build a histogram
            for sample in samples {
                self.histogram[Int(sample.brightnessComponent * 256) % 265] += 1
            }
            
            print("Processed frame \(self.frameCount)");
        }
    }
    
    @IBAction func cancel(sender: AnyObject) {
        manager?.cancelProcessing()
    }
    
    @IBAction func save(sender: AnyObject) {
        for bin in histogram {
            print("\(bin)")
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

