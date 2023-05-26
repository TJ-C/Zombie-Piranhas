//
//  GameScene_WatchOS.swift
//  Zombie Piranhas
//
//  Created by Theo Carper on 18/05/2023.
//  Copyright © 2023 Ray Wenderlich. All rights reserved.
//

import WatchConnectivity
import SpriteKit
import SwiftUI
import CoreMotion

#if os (watchOS)
extension GameScene {

  override func sceneDidLoad() {
    setupScene()
    setupTouchObserver()
  }
  
  /// HowTo - Notifications: https://www.appypie.com/notification-center-how-to-swift
  func setupTouchObserver() {
    NotificationCenter.default.addObserver(self, selector:#selector(didTap(_:)), name: .didTapScreen, object: nil)
//    NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .reload, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(didSwipe), name: .didSwipeUp, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(reelTurn(_:)), name: .didTurnDigitalCrown, object: nil)
  }
  
  @objc func didTap(_ notification: Notification) {
    switch gameState {
    case .readyToCast:
      castLine()
    case .casting:
      stopHook()
    case .reelingIn:
      bashFish()
    case .gameOver:
      resetGame()
    default:
      break
    }
  }
  
  @objc func didSwipe() {
    resetHook()
  }
  
  func updateReel() {
    let hookDepthDelta =
        hookDeltaPerFrame * reelDecelerateFactor
      line!.size.height = line!.size.height - hookDepthDelta
      hook!.position.y = hook!.position.y + hookDepthDelta
      
      if hook!.position.y >= -50.0 {
        hook!.position.y = -50.0
        line!.size.height = 50.0
        reelDecelerateFactor = 0.0
        removeAction(forKey: "ReelSound")
        gameState = .readyToCast
        return
      }
      
      if hook!.position.y <= -1350.0 {
        hook!.position.y = -1350.0
        line!.size.height = 1350.0
        reelDecelerateFactor = 0.0
        removeAction(forKey: "ReelSound")
      }
      
      reelDecelerateFactor = reelDecelerateFactor * 0.95
      
      if reelDecelerateFactor < 0.02 {
        reelDecelerateFactor = 0.0
        gameState = .fishing
        fishingTimer = CFAbsoluteTimeGetCurrent()
      }
    }
  
  @objc func reelTurn(_ notification: Notification) {
    guard let notification = notification.userInfo as? [String: CGFloat] else { return }
    if let rotateSpeed: CGFloat = notification["rotationSpeed"] {
      // 1
      if fishCaught == nil && !hook!.hasActions() {
        gameState = .casting
        // 2
        var hookDeltaMagnitude = abs(rotateSpeed) * 10.0
        hookDeltaMagnitude = min(hookDeltaMagnitude, 20.0)
        // 3
        if reelDecelerateFactor < 0.1 && hookDeltaMagnitude > 6.0 {
          run(reelStartSound, withKey: "ReelSound")
        }
        // 4
        hookDeltaPerFrame = hookDeltaMagnitude * rotateSpeed.sign()
        // 5
        reelDecelerateFactor = 1.0
        tickTimer = CFAbsoluteTimeGetCurrent()
      }
    }
  }
  
  // MARK: - Accelerometer
  func accelerometerUpdate(
      accelerometerData: CMAccelerometerData) {
    if gameState == .readyToCast {
      let screenEdgeBuffer: CGFloat = 67.0
      let xDelta: CGFloat = (size.width * 0.5)
        - boatSprite!.size.width/2 - screenEdgeBuffer
      let acceleration = accelerometerData.acceleration
      let currentXPosition = boatSprite!.position.x
      var positionX = currentXPosition
        + (5.0 * CGFloat(acceleration.x))
          
      // Check boundaries
      if positionX > xDelta {
        positionX = xDelta
      } else if positionX < -xDelta {
        positionX = -xDelta
      }
          
      // Flip boat
      if acceleration.x > 0.1 && boatSprite!.xScale < 0.0 {
        boatSprite?.run(SKAction.scaleX(to: 1.0, duration: 0.5))
      }
      if acceleration.x < -0.1 && boatSprite!.xScale > 0.0 {
        boatSprite?.run(SKAction.scaleX(to: -1.0, duration: 0.5))
      }
          
      boatSprite!.position.x = positionX
    }
  }

  
//  @objc func didTap(_ notification: Notification) {
//    guard let data = notification.userInfo as? [String: CGPoint] else { return }
//    if let location = data["location"] {
//      print("location tapped: \(location) vs fisherman location: \(fisherman?.position)")
//      handlePlayerAction(at: location)
//    }
//  }
}

extension Notification.Name {
  static let didTapScreen = Notification.Name("didTapScreen")
  static let reload = Notification.Name("Reload")
  static let didSwipeUp = Notification.Name("didSwipeUp")
  static let didTurnDigitalCrown = Notification.Name("didTurnDigitalCrown")
}

class WatchGameScene: ObservableObject {
  
  let motionManager = CMMotionManager()
  
  @Published var gameScene: GameScene
  
  init(){
    gameScene = Self.resetGameScene()
    motionManager.accelerometerUpdateInterval = 1.0/30.0
    activateAccelerometer()
  }
  
  static func resetGameScene() -> GameScene {

    let theScene = SKScene(fileNamed: "GameScene")!
    theScene.scaleMode = .aspectFill
    return theScene as! GameScene
  }
  
  func reset() {
    let theScene = SKScene(fileNamed: "GameScene")!
    theScene.scaleMode = .aspectFill
    self.gameScene = theScene as! GameScene
  }
  
  func activateAccelerometer() {
    if motionManager.isAccelerometerAvailable {
      motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
        guard let data = data else { return }
        self.gameScene.accelerometerUpdate(accelerometerData: data)
      }
    }
  }
  
  deinit {
    motionManager.stopAccelerometerUpdates()
  }
}

#endif
