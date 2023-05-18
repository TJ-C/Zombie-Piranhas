//
//  ContentView.swift
//  Zombie Piranhas watchOS Watch App
//
//  Created by Theo Carper on 18/05/2023.
//  Copyright © 2023 Ray Wenderlich. All rights reserved.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
  
  
    var body: some View {
      SpriteView(scene: returnGameScene(), transition: SKTransition.flipHorizontal(withDuration: 0.5), preferredFramesPerSecond: 30)
      
    }
  
  func returnGameScene() -> SKScene  {
    let theScene = SKScene(fileNamed: "GameScene")!
    theScene.scaleMode = .aspectFill
    
    return theScene
    
  }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
