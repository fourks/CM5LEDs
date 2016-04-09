//
//  AppDelegate.swift
//  CM5
//
//  Created by William Dillon on 4/5/16.
//  Copyright © 2016 housedillon. See top level LICENSE file
//

import Cocoa
import AVFoundation

func convertTo16BitHex(colors: [NSColor]) -> [UInt16] {
    var outputArray = [UInt16]()
    
    var counter = 0
    var accumulator: UInt16 = 0
    for color in colors {
        // The 0.43 number is derived from selecting the point on the histogram
        accumulator |= (color.greenComponent > 0.25) ? 1 : 0

        if counter == 15 {
            outputArray.append(accumulator)
            accumulator = 0
            counter = 0
        } else {
            accumulator = accumulator << 1
            counter += 1
        }
    }
    
    return outputArray
}

func hexString(value: UInt16) -> String {
    var nibbles = [Character]()

    nibbles.append("0")
    nibbles.append("x")
    for i in 0..<4 {
        switch( (value << UInt16(4 * i)) & 0xF000) {
        case 0x0000: nibbles.append("0")
        case 0x1000: nibbles.append("1")
        case 0x2000: nibbles.append("2")
        case 0x3000: nibbles.append("3")
        case 0x4000: nibbles.append("4")
        case 0x5000: nibbles.append("5")
        case 0x6000: nibbles.append("6")
        case 0x7000: nibbles.append("7")
        case 0x8000: nibbles.append("8")
        case 0x9000: nibbles.append("9")
        case 0xa000: nibbles.append("A")
        case 0xb000: nibbles.append("B")
        case 0xc000: nibbles.append("C")
        case 0xd000: nibbles.append("D")
        case 0xe000: nibbles.append("E")
        case 0xf000: nibbles.append("F")
        default: continue
        }
    }
    
    return String(nibbles)
}

func collapseSamples(animation: [[UInt16]]) -> [(Int, Int, [UInt16])] {
    var frameCounter = 0
    var stepCounter  = 0

    var lastFrame: [UInt16]? = nil
    var unstable = true

    var outputBuffer = [(Int, Int, [UInt16])]()
    
    for frame in animation {

        if let last = lastFrame {
            let differences = compareFrames(last, rhs: frame)

            // Implement hysteresis.  On the transition to a stable state,
            // which is the first fully no-change pair of frames, output a frame.
            // Once stable, require a change of > 10 to move back into unstable
            if unstable {
                if differences == 0 {
                    unstable = false
                    outputBuffer.append((frameCounter, stepCounter, frame))
                    stepCounter += 1

                }
            } else {
                if differences > 10 {
                    unstable = true
                }
            }
        }
        
        frameCounter += 1
        lastFrame = frame
    }
    
    return outputBuffer
}

// Return the number of rows that are different between frames
func compareFrames(lhs: [UInt16], rhs: [UInt16]) -> Int {
    guard lhs.count == rhs.count else { return Int.max }
    
    var differences = 0
    for i in 0..<lhs.count {
        if lhs[i] != rhs[i] { differences += 1 }
    }
    
    return differences
}

// Assume that one rect is wholly contained within the other
// Return an origin which is the offset of the inner rect within the outer
// and a size that is the absolute difference in size between the rects.
func -(rhs: NSRect, lhs: NSRect) -> NSRect {
    return NSRect(
        x:      abs(rhs.origin.x    - lhs.origin.x),
        y:      abs(rhs.origin.y    - lhs.origin.y),
        width:  abs(rhs.size.width  - lhs.size.width),
        height: abs(rhs.size.height - lhs.size.height)
    )
}

func +(rhs: NSSize, lhs: NSSize) -> NSSize {
    return NSSize(
        width:  rhs.width  + lhs.width,
        height: rhs.height + lhs.height)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var viewer: AlignmentView!

    var manager: AssetManager! = nil
    var sampler: Sampler! = nil
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        manager = AssetManager(
            url: NSURL(fileURLWithPath: "/Users/wdillon/Desktop/Untitled Project.mov")
        )

//        let windowChrome = viewer.bounds - window.frame
//        if let width = manager.width, height = manager.height {
//            viewer.bounds.size = NSSize(width: width, height: height)
//        }

        sampler = Sampler(viewer.grid)
        viewer.sampler = sampler
        
        // Get a starting image about 1/2 through the video
        sampler.image = manager?.generateFrame(CMTime(
            seconds: manager.duration / 2,
            preferredTimescale: 1
        ))

        // Find the difference in window dimensions and view dimensions to find
        // the dimensions of the "chrome" around the view.  We'll get the size
        // of the video file and add it to the window size.
//        window.setFrame(
//            NSRect(
//                origin: window.frame.origin,
//                size:   viewer.bounds.size + windowChrome.size
//            ),
//            display: true)
        
        viewer.needsDisplay = true
    }

    var histogram = [Float](count: 256, repeatedValue: 0)
    var timeline  = [(CGFloat, CGFloat, CGFloat, CGFloat)]()
    var animation = [[UInt16]]()
    
    @IBAction func run(sender: AnyObject?) {
        histogram = [Float](count: 265, repeatedValue: 0)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.viewer.startAnimating()
        }
        
        let lock = NSLock()
        
        manager?.processFrames { (time: CMTime, image: CGImage) in
            lock.protect {
                self.sampler.image = image
                let samples = self.sampler.getSamples(withGrid: self.viewer.grid)
                // Append the top-left sample into the timeline
                self.timeline.append((
                    samples[0].greenComponent,
                    samples[127].greenComponent,
                    samples[255].greenComponent,
                    samples[511].greenComponent
                ))
                
                // Accumulate the value of each sample to build a histogram
                for sample in samples {
                    self.histogram[Int(sample.greenComponent * 255) % 255] += 1
                }
                
                // Create a new animation frame
                self.animation.append(convertTo16BitHex(samples))
            }
        }
    }
    
    @IBAction func cancel(sender: AnyObject) {
        viewer.stopAnimating()
        manager?.cancelProcessing()
    }
    
    @IBAction func save(sender: AnyObject) {
        viewer.stopAnimating()
//        for (s0, s1, s2, s3) in timeline {
//            print("\(s0), \(s1), \(s2), \(s3)")
//        }
//        for bin in histogram {
//            print("\(bin)")
//        }
        for sample in collapseSamples(animation) {
            print("Frame \(sample.0) was the first of step \(sample.1)")
            for row in sample.2 {
                print(hexString(row))
            }
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

