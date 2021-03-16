//
//  ParticleView.swift
//  Metal Music Visualizer
//
//  Last Edited by Matthew Maring on 5/17/2020.
//  Copyright © 2020 Matthew Maring. All rights reserved.
//
// This file handles the metal view and creates all of the buffers
// for the visualization. The code makes use of AVFoundation and
// MetalKit.
//

import Foundation
import MetalKit
import AVFoundation
import CoreAudio

// The audio pieces are sourced from:
// https://www.youtube.com/audiolibrary/music
// which allows for unrestricted use of the included music for projects

struct Particle {
    var position: SIMD2<Float>
    var count: SIMD2<Float> // first digit used for cycle counting, second digit for number of particles
}

struct Music {
    var power: SIMD2<Float> // first digit used for average power, second digit for peak power
    var params: SIMD2<Float> // first digit used intensity, second digit unused
}

public class ParticleView: NSObject, MTKViewDelegate {
    
    public var device: MTLDevice!
    var queue: MTLCommandQueue!
    var disable_lines: Bool
    
    // states for buffer
    var backgroundState: MTLComputePipelineState!
    var particleState: MTLComputePipelineState!
    
    // variables for music buffer
    var musicBuffer: MTLBuffer!
    var musics = [Music]()
    let player : AVAudioPlayer!
    
    // variables for particle buffer
    var particleBuffer: MTLBuffer!
    var particles = [Particle]()
    
    // Init function
    public init(player: AVAudioPlayer, reduce_intensity: Bool) {
        self.player = player
        self.disable_lines = reduce_intensity
        super.init()
        
        // setup all the buffers
        initializeMetal()
        initializeBuffers()
        initializeMusic()
    }
    
    // Get average decibel, range 0 to 160
    func getAverageDecibels(player:AVAudioPlayer) -> Float {
        player.isMeteringEnabled = true
        player.updateMeters()
        return(Float(player.averagePower(forChannel: 0) + 160))
    }
    
    // Get peak decibel, range 0 to 160
    func getPeakDecibels(player:AVAudioPlayer) -> Float {
        player.isMeteringEnabled = true
        player.updateMeters()
        return(Float(player.peakPower(forChannel: 0) + 160))
    }
    
    // Initialize the buffer array
    func initializeBuffers() {
        var count = 0
        for y_cor in 0 ..< 60 {
            for x_cor in 0 ..< 60 {
                particles.append(Particle(
                    position: SIMD2<Float>(Float(8 + x_cor * 20), Float(8 + y_cor * 20)),
                    count: SIMD2<Float>(0, Float(count))
                ))
                count += 1
            }
        }
        
        let size = particles.count * MemoryLayout<Particle>.size
        particleBuffer = device.makeBuffer(bytes: &particles, length: size, options: [])
    }
    
    // Initialize the music array
    func initializeMusic() {
        musics.removeAll()
        var intensity = 1.0
        if (disable_lines == true) {
            intensity = 0.0
        }
        musics.append(Music(
            power: SIMD2<Float>(getAverageDecibels(player: player), getPeakDecibels(player: player)),
            params: SIMD2<Float>(Float(intensity), 0.0)
        ))
        let size = musics.count * MemoryLayout<Music>.size
        musicBuffer = device.makeBuffer(bytes: &musics, length: size, options: [])
    }
    
    // Initialize the metal parameters
    func initializeMetal() {
        device = MTLCreateSystemDefaultDevice()
        queue = device.makeCommandQueue()
        
//        guard let path = Bundle.main.path(forResource: "Shaders", ofType: "metal") else {
//            return
//        }
        
        do {
            let library = device.makeDefaultLibrary()!
            
            // background pass
            guard let backgroundPass = library.makeFunction(name: "initializeBackground") else {
                return
            }
            backgroundState = try device.makeComputePipelineState(function: backgroundPass)
            
            // particle/music pass
            guard let particlePass = library.makeFunction(name: "initializeParticles") else {
                return
            }
            particleState = try device.makeComputePipelineState(function: particlePass)
            
        } catch let e { print(e) }
    }
    
    // Needed, but not used
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    // Draw the metal environment
    public func draw(in view: MTKView) {
        if let drawable = view.currentDrawable,
           let commandBuffer = queue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            // background
            commandEncoder.setComputePipelineState(backgroundState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            let w = backgroundState.threadExecutionWidth
            let h = backgroundState.maxTotalThreadsPerThreadgroup / w
            let threadsPerGroup = MTLSizeMake(w, h, 1)
            var threadsPerGrid = MTLSizeMake(1200, 1200, 1)
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
            
            // particles/music/random
            initializeMusic()
            commandEncoder.setComputePipelineState(particleState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            commandEncoder.setBuffer(particleBuffer, offset: 0, index: 0) //particles
            commandEncoder.setBuffer(musicBuffer, offset: 0, index: 1) // music
            threadsPerGrid = MTLSizeMake(particles.count, 1, 1)
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
            
            // send
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

