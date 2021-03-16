/*:
MetalMusicVisualizer.playground for 2020 Apple World Wide Developer Conference, WWDC Scholarship,
©2020 Matthew Hayden Maring, Age 19, Waterville, Maine, Cincinnati, Ohio, Colby College
*/
import UIKit
import Foundation
import MetalKit
import PlaygroundSupport
import AVFoundation
import CoreAudio
/*:
# Metal Music Visualizer
This playground uses **AVFoundation** and **Metal** to create a music synthesizer.
 
Note: Depending on the type of display used, the colors may be too intense and will not render optimally. If you find that this needs adjustment, you can disable the background lines by setting the following property to true!
*/
let disable_lines = false
/*:
Specify a track to play using the variable SongToPlay. I recommend listening to "Reverse" for 90 seconds/until the bass drop, then briefly sampling "Thunder" and "Jubilee" with the remaining time.
 * "Reverse" is an upbeat electronic style piece that contains a variety of rhythms and sudden pitch changes that make a unique visualization. Look out for the bass drop around the 1:15 mark!
 * "Thunder" is another upbeat electronic style piece with more of a melody throughout the piece. Look out for the build-up of the rhythm and how it affects the choppiness of the visualization!
 * "Jubilee" is an older electronic style piece with distinctive beats that can be seen in the visualization quite well. Look out for the slides on the guitar that will correspond to the diagonal bars sliding back and forth!
*/
let songToPlay = "Reverse"
// let songToPlay = "Thunder"
// let songToPlay = "Jubilee"
/*:
The rest of the code will:
 * Create an **AVAudioPlayer** to play the sound
 * Make sure indefinite execution is enabled
 * Create the view
 * Set the live view to the metal music visualization
*/
/*:
Enjoy!
*/
let player = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: songToPlay, withExtension: "aac")!)
player.play()
PlaygroundPage.current.needsIndefiniteExecution = true
let frame = CGRect(x: 0.0, y: 0.0, width: 600.0, height: 600.0) // scaling must be 600
let mView = ParticleView(player: player, reduce_intensity: disable_lines)
let view = MTKView(frame: frame, device: mView.device)
view.delegate = mView
PlaygroundPage.current.liveView = view
