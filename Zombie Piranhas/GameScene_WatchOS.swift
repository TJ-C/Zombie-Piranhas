//
//  GameScene_WatchOS.swift
//  Zombie Piranhas
//
//  Created by Theo Carper on 18/05/2023.
//  Copyright © 2023 Ray Wenderlich. All rights reserved.
//

import WatchConnectivity
import SpriteKit

#if os (watchOS)
extension GameScene {
  override func sceneDidLoad() {
    setupScene()
  }
}
#endif
