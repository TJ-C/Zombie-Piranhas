/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
#if os(macOS) || os(tvOS)
import GameController
#endif
#if os(watchOS)
import SwiftUI
import WatchKit
#endif


#if os(macOS) || os(tvOS)
protocol ReactToMotionEvents {
  func motionUpdate(_ motion: GCMotion) -> Void
}
#endif

// States
enum GameState: Int {
  case readyToCast
  case casting
  case fishing
  case reelingIn
  case collectingFish
  case gameOver
}

class GameScene: SKScene {
  
  var fishCam: SKCameraNode?
  var boatSprite: SKSpriteNode?
  var fisherman: SKSpriteNode?
  var pole: SKSpriteNode?
  var hook: SKSpriteNode?
  var line: SKSpriteNode?
  // Game state
  var gameState: GameState = .readyToCast
  //
  // Timers
  var cloudTimer: Double = 0.0
  var fishTimer: Double = 0.0
  var tickTimer: Double = 0.0
  var fishingTimer: Double = 0.0
  //
  var yumFish: SKSpriteNode?
  var piranha: SKSpriteNode?
  var fishCaught: SKNode?

  var score: Int = 0
  var lives: Int = 1
  // Labels
  var scoreLabel: SKLabelNode?
  var livesLabel: SKLabelNode?
  var statusLabel: SKLabelNode?
  //
  // Sounds
  var reelStartSound = SKAction.playSoundFileNamed("Reel Start Sound", waitForCompletion: false)
  var reelTickSound = SKAction.playSoundFileNamed("Reel Tick Sound", waitForCompletion: false)
  var yumFishSound = SKAction.playSoundFileNamed("Yum Fish Sound", waitForCompletion: false)
  var zombieSound = SKAction.playSoundFileNamed("Zombie Sound", waitForCompletion: false)
  var gameOverSound = SKAction.playSoundFileNamed("Game Over Sound", waitForCompletion: true)
  var fishCaughtSound = SKAction.playSoundFileNamed("Fish Caught", waitForCompletion: false)
  var fishBashSound = SKAction.playSoundFileNamed("Fish Bash Sound", waitForCompletion: false)
  var fishOffSound = SKAction.playSoundFileNamed("Fish Off Sound", waitForCompletion: false)
  
  // Scaling for macOS
  var sceneContentScale: CGFloat = 1.0
  
  // Challenge
  var boatDirectionToTheRight = true
  var rotate = SKAction.scaleX(to: -1, duration: 2)
 
  #if os(macOS) || os(tvOS)
  // Controllers
  var curController: GCController?
  var motionSupported: Bool = false
  var motionDelegate: ReactToMotionEvents? = nil
  
  func gcAccelerationToDouble3(_ acceleration: GCAcceleration) -> simd_double3 {
      return simd_make_double3(acceleration.x, acceleration.y, acceleration.z)
  }
  #endif
  
  #if !os(watchOS)
  override func didMove(to view: SKView) {
    setupScene()
    #if os(macOS) || os(tvOS)
    setupControllerObservers()
    connectControllers()
    #endif
  }
  #endif
  
  #if os(watchOS)
  var hookDeltaPerFrame: CGFloat = 0
  var reelDecelerateFactor: CGFloat = 0
  #endif
  
  func setupScene() {
    // Set up camera
    fishCam = childNode(withName: "fishCam") as? SKCameraNode
    camera = fishCam
    
    boatSprite = childNode(withName: "boat") as? SKSpriteNode
    fisherman = boatSprite?.childNode(withName: "fisherman") as? SKSpriteNode
    pole = boatSprite?.childNode(withName: "pole") as? SKSpriteNode
    line = childNode(withName: "line") as? SKSpriteNode
    hook = line?.childNode(withName: "hook") as? SKSpriteNode
    yumFish = childNode(withName: "yumFish") as? SKSpriteNode
    yumFish?.isHidden = true
    piranha = childNode(withName: "piranha") as? SKSpriteNode
    piranha?.isHidden = true
    
    statusLabel = childNode(withName: "statusLabel") as? SKLabelNode
    scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
    livesLabel = childNode(withName: "livesLabel") as? SKLabelNode
    
    // macOS Stuff
    #if os(macOS)
    let labelYScaleFactor: CGFloat = 0.87
    statusLabel!.position.y = statusLabel!.position.y * labelYScaleFactor
    scoreLabel!.position.y = scoreLabel!.position.y * labelYScaleFactor
    livesLabel!.position.y = livesLabel!.position.y * labelYScaleFactor
    sceneContentScale = 0.5
    #endif
    
    #if os(tvOS)
    let labelYScaleFactor: CGFloat = 0.85
    let labelXScaleFactor: CGFloat = 0.92
        
    statusLabel!.position.y =
      statusLabel!.position.y * labelYScaleFactor
    scoreLabel!.position.y =
      scoreLabel!.position.y * labelYScaleFactor
    livesLabel!.position.y =
      livesLabel!.position.y * labelYScaleFactor
        
    scoreLabel!.position.x =
      scoreLabel!.position.x * labelXScaleFactor
    livesLabel!.position.x =
      livesLabel!.position.x * labelXScaleFactor
        
    sceneContentScale = 0.5
    
//    let tapRecognizer = UITapGestureRecognizer(target: self,
//                                               action: #selector(remoteTapped(_:)))
//    tapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue), NSNumber(value: UIPress.PressType.downArrow.rawValue)]
//
//    view!.addGestureRecognizer(tapRecognizer)
//    let appDelegate = UIApplication.shared.delegate as! GameScene
//    appDelegate.motionDelegate = self
    #endif
    
    boatSprite!.setScale(sceneContentScale)
    line!.setScale(sceneContentScale)
    scoreLabel!.setScale(sceneContentScale)
    livesLabel?.setScale(sceneContentScale)
    
    (childNode(withName: "bubbles") as? SKEmitterNode)?.advanceSimulationTime(60.0)
    
    // Rock the boat
    let rotate1 = SKAction.rotate(toAngle: CGFloat(-8.0).degreesToRadians(), duration: 4.0)
    let rotate2 = SKAction.rotate(toAngle: CGFloat(8.0).degreesToRadians(), duration: 4.0)
    rotate1.timingMode = SKActionTimingMode.easeInEaseOut
    rotate2.timingMode = SKActionTimingMode.easeInEaseOut
    let rockSequence = SKAction.sequence([rotate1, rotate2])
    boatSprite?.run(SKAction.repeatForever(rockSequence))
    
    updateScore()
    
    for _ in 0...10 {
      generateCloud(scatterX: true)
    }
    #if os(watchOS)
    spawnFish(type: yumFish!, amount: 5)
    spawnFish(type: piranha!, amount: 10)
    #else
    spawnFish(type: yumFish!, amount: 10)
    spawnFish(type: piranha!, amount: 20)
    #endif
    
    let backgroundAudio = SKAudioNode(fileNamed: "Fishing Ambience Sound")
    addChild(backgroundAudio)
    updateStatus(text: "Ready.", color: SKColor.blue)
  }
  
  func castLine() {
    if gameState == .readyToCast {
      gameState = .casting
      
      #if os(iOS)
      let hookDepth = CGFloat(3600.0)
      #elseif os(macOS) || os(tvOS)
      let hookDepth = CGFloat(7000)
      #elseif os(watchOS)
      let hookDepth = CGFloat(1350)
      WKInterfaceDevice.current().play(.start)
      #endif
      let hookVelocity = Double(hookDepth / 500)
      
      castAndReel(depth: hookDepth, speed: hookVelocity, completion: {
        self.gameState = .fishing
        self.fishingTimer = CFAbsoluteTimeGetCurrent()
        #if os(watchOS)
        WKInterfaceDevice.current().play(.stop)
        #endif
      })
    }
  }
  
  func stopHook() {
    if gameState == .casting {
      let hookPosition = convert((hook?.position)!, from: line!)
      if hookPosition.y < (boatSprite!.position.y - hook!.size.height) {
        hook?.removeAllActions()
        line?.removeAllActions()
        gameState = .fishing
        fishingTimer = CFAbsoluteTimeGetCurrent()
        #if os(watchOS)
        reelDecelerateFactor = 0
        WKInterfaceDevice.current().play(.stop)
        #endif
      }
    }
  }
  
  func resetHook() {
    if gameState == .fishing {
      gameState = .reelingIn
      
      #if os(watchOS)
      let targetDepth = CGFloat(50.0)
      #else
      let targetDepth = CGFloat(100.0)
      #endif
      let currentDepth = line!.size.height
      let hookVelocity = Double(currentDepth / 500)
      
      if fishCaught != nil {
        let rotate1 = SKAction.rotate(toAngle: CGFloat(85.0).degreesToRadians(), duration: 0.1)
        let rotate2 = SKAction.rotate(toAngle: CGFloat(95.0).degreesToRadians(), duration: 0.1)
        fishCaught?.run(SKAction.repeatForever(SKAction.sequence([rotate1, rotate2])))
      }
      
      castAndReel(depth: targetDepth, speed: hookVelocity, completion: {
        self.gameState = .collectingFish
        self.camera?.removeAllActions()
        self.camera!.position = CGPoint(x: 0.0, y: self.boatSprite!.position.y)
        self.checkForFish()
      })
    }
  }
  
  
  func castAndReel(depth: CGFloat, speed: Double, completion: @escaping () -> ()) {
    statusLabel?.isHidden = true
    statusLabel?.removeAllActions()
    
    let lineAction = SKAction.resize(toHeight: depth, duration: speed)
    lineAction.timingMode = SKActionTimingMode.easeOut
    
    let hookAction = SKAction.moveTo(y: -depth, duration: speed)
    hookAction.timingMode = SKActionTimingMode.easeOut
    
    hook?.run(hookAction)
    line?.run(lineAction, completion: completion)
    run(reelStartSound, withKey: "ReelSound")
    tickTimer = CFAbsoluteTimeGetCurrent()
  }
  
  func generateCloud(scatterX: Bool) {
    let cloud = SKSpriteNode(imageNamed: "Cloud")
    cloud.alpha = CGFloat.random(min: 0.5, max: 1.0)
    cloud.zPosition = -3
    cloud.setScale(CGFloat.random(min: 0.5, max: 1.0))
    cloud.yScale = cloud.yScale * CGFloat.random(min: 0.25, max: 0.75)
    
    var initialXPosition: CGFloat
    let screenDelta = (size.width * 0.5) + (cloud.size.width / 2)
    if scatterX {
      initialXPosition = CGFloat.random(min: -screenDelta, max: screenDelta)
    } else {
      initialXPosition = -screenDelta
    }
    
    let yPosition = CGFloat.random(min: size.height * 0.40, max: size.height * 0.5)
    
    cloud.position = CGPoint(x: initialXPosition, y: yPosition)
    
    let velocityDelta = (size.height * 0.5) / yPosition
    let velocity = Double(60.0 * velocityDelta)
    
    let moveCloud = SKAction.moveTo(x: size.width * 0.5 + (cloud.size.width / 2), duration: velocity)
    cloud.run(moveCloud) {
      cloud.removeFromParent()
    }
    
    addChild(cloud)
  }
  
  func spawnFish(type: SKSpriteNode, amount: Int) {
    for _ in 0..<amount {
      if let fishSprite = type.copy() as? SKSpriteNode {
        fishSprite.isHidden = false
        
        let fishScale = CGFloat.random(min: 0.40, max: 1.0)
        fishSprite.userData?["fishScale"] = fishScale
        fishSprite.setScale(fishScale * sceneContentScale)
        
        let fishSpeed = fishSprite.userData?["speed"] as! CGFloat
        fishSprite.userData?["speed"] = fishSpeed * CGFloat.random(min: 0.5, max: 1.0)
        
        let fishLife = fishSprite.userData?["life"] as! CGFloat
        fishSprite.userData?["life"] = fishLife * fishScale

        let xDelta: CGFloat = (size.width * 0.5) + (fishSprite.size.width / 2.0)
        
        #if os(watchOS)
        let fishY = CGFloat.random(min: -700, max: 515)
        #else
        let fishY = CGFloat.random(min: -1900.0, max: 1450.0)
        #endif
        
        var fishX = -xDelta
        if CGFloat.random(min: 0.0, max: 100.0) <= 50.0 {
          fishSprite.xScale = -fishSprite.xScale
          fishX = xDelta
        }
        fishSprite.position = CGPoint(x: fishX, y: fishY)
        
        addChild(fishSprite)
      }
    }
  }
  
  func spawnRandomFish() {
    if CGFloat.random(min: 0.0, max: 100.0) <= 50.0 {
      spawnFish(type: yumFish!, amount: 1)
    } else {
      spawnFish(type: piranha!, amount: 1)
    }
  }
  
  func updateFish(fish: SKNode) {
    
    #if os(watchOS)
    let hookRadius: CGFloat = 50
    let offset = CGPoint(x: 6, y: 30)
    #else
    let hookRadius:CGFloat = 100
    let offset = CGPoint(x: 12, y: 60)
    #endif
    
    // Check if fish is near hook.
    let hookPosition = convert((hook?.position)!, from: line!)
    // Take into account the hooks anchorPoint.
    let convertedHookPosition = CGPoint(x: hookPosition.x - offset.x, y: hookPosition.y - offset.y)
    
    if gameState == .fishing && fishCaught == nil {
      if fish.userData?["caught"] as! Bool == false {
        let distance = fish.position.distanceTo(convertedHookPosition)
        
        if distance < hookRadius {
          fish.userData?["active"] = true
          fishingTimer = CFAbsoluteTimeGetCurrent()
        } else {
          fish.userData?["active"] = false
        }
      }
      
      // If active...
      if fish.userData?["active"] as! Bool == true {
        // Roll the dice to see if fish takes the bait...
        if fish.userData?["caught"] as! Bool == false {
          if CFAbsoluteTimeGetCurrent() - fishTimer > 1.0 {
            let dice = round(CGFloat.random(min: 0.0, max: 100.0))
            if dice <= 25.0 {
              // Catch fish!
              fish.userData?["caught"] = true
              catchFish(fish: fish)
            }
            fishTimer = CFAbsoluteTimeGetCurrent()
          }
        }
      }
    }
    
    if gameState != .fishing || fish.userData?["active"] as! Bool == false {
      // Passive swimming.
      let speed = fish.userData?["speed"] as! CGFloat
      let xDelta: CGFloat = (size.width * 0.5) + (fish as! SKSpriteNode).size.width
      if fish.xScale < 0.0 {
        // Move fish left.
        fish.position = CGPoint(x: fish.position.x - speed, y: fish.position.y)
        
        // Check boundary.
        if fish.position.x < -xDelta {
          fish.removeFromParent()
          spawnRandomFish()
        }
      } else {
        // Move fish right.
        fish.position = CGPoint(x: fish.position.x + speed, y: fish.position.y)
        
        // Check boundary.
        if fish.position.x > xDelta {
          fish.removeFromParent()
          spawnRandomFish()
        }
      }
    }
  }
  
  func catchFish(fish: SKNode) {
    if fish.xScale < 0.0 {
      fish.xScale *= -1.0
    }
    
    fishCaught = fish.copy() as! SKSpriteNode
    fish.removeFromParent()
    fishCaught?.setScale(fish.userData?["fishScale"] as! CGFloat)

    #if os(watchOS)
    fishCaught!.position = CGPoint(x: -6, y: -30)
    #else
    fishCaught!.position = CGPoint(x: -12.0, y: -60.0)
    #endif
    
    fishCaught!.zRotation = CGFloat(90.0).degreesToRadians()
    fishCaught!.zPosition = fishCaught!.zPosition + 1
    
    hook?.addChild(fishCaught!)
    
    let splash = SKEmitterNode(fileNamed: "Splash")
    splash!.targetNode = self
    fishCaught?.addChild(splash!)
    
    let shakeAmount = CGPoint(x: 0, y: -(150.0 * fishCaught!.yScale))
    let shakeAction = SKAction.screenShakeWithNode(camera!, amount: shakeAmount, oscillations: 10, duration: 2.0)
    camera?.run(shakeAction)
    
    run(fishCaughtSound)
    resetHook()
  }
  
  func checkForFish() {
    if fishCaught != nil {
      if fishCaught?.name == "piranha" {
        // Decrement Lives
        fisherman?.texture = SKTexture(imageNamed: "FisherZombie_Side")
        lives -= 1
        if lives <= 0 {
           gameOver()
          return
        } else {
          updateStatus(text: "Zombie Piranha!", color: SKColor.red)
          run(zombieSound)
        }
      } else {
        // Increment Score
        if (fishCaught as! SKSpriteNode).yScale > 0.75 {
          updateStatus(text: "Nice Fish! +1 Bonus!", color: SKColor.blue)
          score += 2
        } else {
          updateStatus(text: "Yum Fish!", color: SKColor.blue)
          score += 1
        }
        run(yumFishSound)
      }
      fishCaught?.run(SKAction.sequence([SKAction.wait(forDuration: 3.0), SKAction.fadeOut(withDuration: 0.25)]), completion: {
        self.fishCaught?.removeFromParent()
        self.fishCaught = nil
        self.fisherman?.texture = SKTexture(imageNamed: "Fisherman_Side")
        self.updateStatus(text: "Ready.", color: SKColor.blue)
        self.gameState = .readyToCast
      })
      updateScore()
      spawnRandomFish()
    } else {
      updateStatus(text: "Ready.", color: SKColor.blue)
      gameState = .readyToCast
      #if os(watchOS)
      WKInterfaceDevice.current().play(.retry)
      #endif
    }
  }
  
  func bashFish() {
    if gameState == .reelingIn && fishCaught?.name == "piranha" {
      if fishCaught?.userData?["bashed"] as? Bool == true {
        return
      }
      (fishCaught as! SKSpriteNode).color = SKColor.red
      (fishCaught as! SKSpriteNode).colorBlendFactor = 1.0
      
      var life = fishCaught?.userData?["life"] as! CGFloat
      life -= CGFloat.random(min: 0.25, max: 1.0)
      
      if life <= 0.0 {
        fishCaught?.userData?["bashed"] = true
        fishCaught?.run(SKAction.fadeOut(withDuration: 0.25), completion: {
          self.fishCaught?.removeFromParent()
          self.fishCaught = nil
        })
        run(fishOffSound)
      } else {
        fishCaught?.userData?["life"] = life
        fishCaught?.run(SKAction.wait(forDuration: 0.1)) {
          (self.fishCaught as? SKSpriteNode)?.colorBlendFactor = 0.0
        }
        run(fishBashSound)
      }
    }
  }
  
  func updateScore() {
    scoreLabel?.text = "Fish: \(score)"
    livesLabel?.text = "Fishermen: \(lives)"
  }
  
  func updateStatus(text: String, color: SKColor) {
    statusLabel?.text = text
    statusLabel?.fontColor = color
    statusLabel?.setScale(0.0)
    
    statusLabel?.run(SKAction.sequence([SKAction.unhide(),
                                        SKAction.scale(to: 1.0, duration: 0.25),
                                        SKAction.wait(forDuration: 2.0),
                                        SKAction.scale(to: 0.0, duration: 0.25),
                                        SKAction.hide()]))
  }
  
  func gameOver() {
    livesLabel?.text = "Fishermen: 0"
    statusLabel?.text = "GAME OVER!"
    statusLabel?.fontColor = SKColor.red
    statusLabel?.setScale(0.0)
    
    let rotate1 = SKAction.rotate(toAngle: CGFloat(-2.0).degreesToRadians(), duration: 0.1)
    let rotate2 = SKAction.rotate(toAngle: CGFloat(2.0).degreesToRadians(), duration: 0.1)
    
    statusLabel?.run(SKAction.sequence([SKAction.unhide(),
                                        SKAction.scale(to: 1.75, duration: 0.25)]))
    
    statusLabel?.run(SKAction.repeatForever(SKAction.sequence([rotate1, rotate2])))
    run(gameOverSound) {
      self.gameState = .gameOver
    }
  }
  
  func resetGame() {
    #if os(watchOS)
    NotificationCenter.default.post(name: NSNotification.Name("Reload"), object: self)
    #else
    let newScene = GameScene(fileNamed:"GameScene")
    newScene!.scaleMode = .aspectFill
    let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
    view?.presentScene(newScene!, transition: reveal)
    #endif
  }
  
  // Challenge
  #if os(macOS) || os(tvOS)
  /// Updates the boat's direction after the boat comes near to the edge of the screen.
  /// - Parameter boat: the fishing boat
  func updateBoat(boat: SKNode) {
    if gameState == .readyToCast {
      let speed = boat.userData?["speed"] as! CGFloat
      let xDelta: CGFloat = (size.width * 0.5) + (boat as! SKSpriteNode).size.width
      if boatDirectionToTheRight {
        boat.position = CGPoint(x: boat.position.x + speed, y: boat.position.y)
        if boat.position.x > xDelta - (boat.frame.width * 2) {
          // spin boat to the left
          boatDirectionToTheRight = false
//          boat.xScale = boat.xScale * -1
          boat.run(SKAction.scaleX(to: boat.xScale * -1, duration: 1))
        }
      } else { // going left
        boat.position = CGPoint(x: boat.position.x - speed, y: boat.position.y)
        if boat.position.x < -(xDelta - (boat.frame.width * 2)) {
          // spin boat to the right
          boatDirectionToTheRight = true
          boat.run(SKAction.scaleX(to: boat.xScale * -1, duration: 1))
        }
      }
    }
  }
  #endif
  
  // MARK: - Events
 
  #if os(iOS)
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let touchLocation = touches.first?.location(in: self)
    handlePlayerAction(at: touchLocation!)
  }
  #endif
  
  func handlePlayerAction(at location: CGPoint) {
    switch gameState {
    case .readyToCast:
      pollBoat(location: location)
    case .casting:
      stopHook()
    case .reelingIn:
      pollHook(location: location)
    case .gameOver:
      resetGame()
    default:
      break
    }
  }
  
  func pollBoat(location: CGPoint) {
    for node in nodes(at: location) {
      if let buttonName = node.name {
        if buttonName == "fisherman" {
          castLine()
          return
        }
      }
    }
  }
  
  func pollHook(location: CGPoint) {
    if fishCaught?.name != "piranha" {
      return
    }
    for node in nodes(at: location) {
      if let buttonName = node.name {
        if buttonName == "hook" {
          bashFish()
          return
        }
      }
    }
  }
  
  override func update(_ currentTime: TimeInterval) {
    // Called before each frame is rendered
    // Update fishing line.
    line?.position = convert(CGPoint(x: 0.0, y: 0.0), from: pole!)
    
    // Update Camera
    let hookPosition = convert((hook?.position)!, from: line!)
    #if os(iOS)
    let maxCameraDepth: CGFloat = -1545
    #elseif os(macOS) || os(tvOS)
    let maxCameraDepth: CGFloat = -1800
    #elseif os(watchOS)
    let maxCameraDepth: CGFloat = -600
    #endif
    if hookPosition.y < (boatSprite?.position.y)! && hookPosition.y > maxCameraDepth {
      camera?.position = CGPoint(x: 0.0, y: hookPosition.y)
    }

    if gameState == .casting || gameState == .reelingIn {
      // Play tick sound
      if CFAbsoluteTimeGetCurrent() - tickTimer > 0.1 {
        run(reelTickSound)
        tickTimer = CFAbsoluteTimeGetCurrent()
      }
    }
    
    // Cloud Generation
    if CFAbsoluteTimeGetCurrent() - cloudTimer > 5.0 {
      if CGFloat.random(min: 0.0, max: 100.0) <= 75.0 {
        generateCloud(scatterX: false)
      }
      cloudTimer = CFAbsoluteTimeGetCurrent()
    }
    
    // Update Fish
    enumerateChildNodes(withName: "yumFish") { (node, stop) in
      self.updateFish(fish: node)
    }
    
    enumerateChildNodes(withName: "piranha") { (node, stop) in
      self.updateFish(fish: node)
    }
    
    // Check fishing timer
    if gameState == .fishing {
      if CFAbsoluteTimeGetCurrent() - fishingTimer > 5.0 {
        resetHook()
      }
    }
    
    // Challenge
    // Update boat
    #if os(macOS) || os(tvOS)
    enumerateChildNodes(withName: "boat") { (node, stop) in
      self.updateBoat(boat: node)
    }
    
//    updateBoat(boat: boatSprite!)
    if curController != GCController.current {
      if let motion = curController?.motion {
        print("Stop detecting casting")
        stopCastingDetection(motion)
      }
      
      curController = GCController.current
      // For some reason this is not supported in tvOS
      if let motion = curController?.motion {
        print("Start detecting casting")
        motionDelegate = self
        curController?.motion?.valueChangedHandler = { motion in
          self.motionDelegate?.motionUpdate(motion)
        }
        startCastingDetection(motion)
      }
    }
    #endif
    
    // Digital crown
    #if os(watchOS)
    if reelDecelerateFactor > 0 {
      updateReel()
    }
    #endif
  }
  
}

#if os(macOS)
// macOS events
extension GameScene {
  override func mouseDown(with event: NSEvent) {
    let location = event.location(in: self)
    handlePlayerAction(at: location)
  }
  
  override func keyDown(with event: NSEvent) {
    guard !event.isARepeat else { return }
    
    let keyCode: UInt16 = event.keyCode
    if keyCode == 49 { // Spacebar
      if gameState == .readyToCast {
        castLine()
      } else {
        stopHook()
      }
    } else if keyCode == 11 { // 'B' key
      bashFish()
    } else {
      super.keyDown(with: event)
    }
  }
}
#endif

#if os(tvOS) || os(macOS)
// tvOS Events
extension GameScene: ReactToMotionEvents {
  
  func stopCastingDetection(_ motion: GCMotion) {
    motion.sensorsActive = false
  }
  
  func startCastingDetection(_ motion: GCMotion) {
    print("Start casting detection...")
    motion.sensorsActive = true
  }
  
  /// When the D-pad left or right buttons are pressed, the boat is rotated to that direction
  /// - Parameter direction: A string describing the direction
  func boatDirection(_ direction: String) {
    if gameState == .readyToCast {
      if direction == "Right" {
        if boatSprite!.xScale < 0.0 {
          // flip  boat right
          boatSprite?.run(SKAction.scaleX(to: sceneContentScale, duration: 0.5))
          boatDirectionToTheRight = true
        }
      } else if direction == "Left" {
        boatSprite?.run(SKAction.scaleX(to: -sceneContentScale, duration: 0.5))
        boatDirectionToTheRight = false
      }
    }
  }

  func motionUpdate(_ motion: GCMotion) {
    let acceleration = gcAccelerationToDouble3(motion.acceleration)
    if acceleration.y > 3 {
      if gameState == .reelingIn {
        bashFish()
      } else {
        goFish()
      }
    }
  }

  
  func goFish() {
    if gameState == .readyToCast {
      castLine()
    } else if gameState == .casting {
      stopHook()
    } else if gameState == .gameOver {
      resetGame()
    }
  }
}
#endif

