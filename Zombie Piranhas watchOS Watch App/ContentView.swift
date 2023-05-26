//
//  ContentView.swift
//  Zombie Piranhas watchOS Watch App
//
//  Created by Theo Carper on 18/05/2023.
//  Copyright © 2023 Ray Wenderlich. All rights reserved.
//

import SwiftUI
import SpriteKit
import CoreMotion

struct ContentView: View {
  
  @Environment(\.scenePhase) private var scenePhaces
  
  @StateObject var watchGameScene = WatchGameScene()
  @State private var viewSate = CGSize.zero
  @State private var crownRotation: Double = 0
  /*
  * HowTo - Notifications: https://www.appypie.com/notification-center-how-to-swift
  * https://www.leadbycode.com/2022/02/how-to-use-notificationcenter-in-swiftui-with-example.html
   * HowTo - Swipe Gestures https://ryanremaly.medium.com/swipe-gesture-navigation-with-swiftui-e81d520f4174
   */
  
  var body: some View {
    GeometryReader { g in
      SpriteView(scene: watchGameScene.gameScene, transition: SKTransition.flipHorizontal(withDuration: 0.5), preferredFramesPerSecond: 30)
        .onTapGesture(coordinateSpace: .global) { location in
          NotificationCenter.default.post(name: .didTapScreen, object: nil, userInfo: ["location": convertFrom(g.size, to: location)])
        }
        .gesture(DragGesture().onChanged { value in
              viewSate = value.translation
            }
          .onEnded({ value in
            if value.predictedEndTranslation.height < g.size.height/2 {
              NotificationCenter.default.post(name: .didSwipeUp, object: nil)
            }
          })
        )
        .onReceive(NotificationCenter.default.publisher(for: .reload)) { _ in
          watchGameScene.reset()
        }
        .focusable(true)
        .digitalCrownRotation($crownRotation) { event in
          let rotateSpeed = CGFloat(event.velocity)
          if rotateSpeed != 0 {
            NotificationCenter.default.post(name: .didTurnDigitalCrown, object: nil, userInfo: ["rotationSpeed" : rotateSpeed])
          }
        }
        
          
    }
    .ignoresSafeArea()
//    .onDisappear() {
//      watchGameScene.motionManager.stopAccelerometerUpdates()
//    }
    
  }
  
//  func returnGameScene() -> SKScene  {
//
//    let theScene = SKScene(fileNamed: "GameScene")!
//    theScene.scaleMode = .aspectFill
//    
//    return theScene
//  }
  
  /// Converts a SwiftUI location to a coordinated location where 0 is the centre of the screen
  /// - Parameters:
  ///   - size: size of the visible watch screen
  ///   - location: location of the tap
  /// - Returns: the location as a coordinated location
  func convertFrom(_ size: CGSize, to location: CGPoint) -> CGPoint {
    let centre = CGPoint(x: size.width/2, y: size.height/2)
    
    return CGPoint(x: location.x - centre.x, y: location.y - centre.y)
    
  }
  
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
