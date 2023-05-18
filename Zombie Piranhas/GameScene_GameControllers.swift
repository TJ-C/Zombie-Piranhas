//
//  GameScene_GameControllers.swift
//  Zombie Piranhas
//
//  Created by Theo Carper on 11/05/2023.
//  Copyright © 2023 Ray Wenderlich. All rights reserved.
//

import Foundation
import SpriteKit
import GameController
#if os(tvOS) || os(macOS)
extension GameScene {
  
  func setupControllerObservers() {
    
    NotificationCenter.default.addObserver(self, selector:#selector(connectControllers), name: NSNotification.Name.GCControllerDidConnect, object: nil)
    NotificationCenter.default.addObserver(self, selector:#selector(controllerDisconnected), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
    
  }
  
  @objc func controllerDisconnected() {
    isPaused = true
  }
  
  @objc func connectControllers() {
    isPaused = false
    
    for controller in GCController.controllers() {
      if controller.extendedGamepad != nil {
        controller.extendedGamepad?.valueChangedHandler = nil
        setupExtendedController(controller)
      }
    }
      
#if os(tvOS)
      for controller in GCController.controllers() {
        if controller.extendedGamepad != nil {
          // ignore
        } else if controller.microGamepad != nil {
          controller.microGamepad?.valueChangedHandler = nil
          setupMicroController(controller)
        }
      }
#endif
    
    func setupExtendedController(_ controller:GCController) {
      // Buttons pressed
      controller.extendedGamepad?.valueChangedHandler = { (gamepad: GCExtendedGamepad, element:GCControllerElement) in
        if (gamepad.controller?.playerIndex == .index1) {
          // this is player 1 playing the controller
        } else if (gamepad.controller?.playerIndex == .index2) {
          // this is player 1 playing the controller
        }
        
        if (gamepad.leftThumbstick == element) {
          if (gamepad.leftThumbstick.left.value > 0.2) {
            print("pressed leftThumbstick left")
          } else if (gamepad.leftThumbstick.left.isPressed == false) {
            print ("let go of leftThumbstick left")
          } else if (gamepad.leftThumbstick.right.value > 0.2) {
            print("pressed leftThumbstick right")
          } else if (gamepad.leftThumbstick.right.isPressed == false) {
            print ("let go of leftThumbstick right")
          }
        } else if (gamepad.rightThumbstick == element) {
          if (gamepad.rightThumbstick.right.value > 0.2) {
            print("pressed rightThumbstick right")
          } else if (gamepad.rightThumbstick.right.isPressed == false) {
            print ("let go of rightThumbstick right")
          }
        } else if (gamepad.dpad == element) {
          if (gamepad.dpad.right.isPressed == true){
            self.boatDirection("Right")
          } else if gamepad.dpad.left.isPressed == true {
            self.boatDirection("Left")
          }
        } else if (gamepad.leftShoulder == element){
          if ( gamepad.leftShoulder.isPressed == true){
            print("leftShoulder pressed")
          } else if ( gamepad.leftShoulder.isPressed == false) {
            print("leftShoulder released")
          }
        }
        else if (gamepad.leftTrigger == element){
          if ( gamepad.leftTrigger.isPressed == true){
            print("leftTrigger pressed")
          } else if ( gamepad.leftTrigger.isPressed == false) {
            print("leftTrigger released")
          }
        }
        else if (gamepad.rightShoulder == element){
          if ( gamepad.rightShoulder.isPressed == true){
            print("rightShoulder pressed")
          } else if ( gamepad.rightShoulder.isPressed == false) {
            print("rightShoulder released")
          }
        }
        else if (gamepad.rightTrigger == element){
          if ( gamepad.rightTrigger.isPressed == true){
            print("rightTrigger pressed")
          } else if ( gamepad.rightTrigger.isPressed == false) {
            print("rightTrigger released")
          }
        } else if ( gamepad.buttonA == element) {
          if ( gamepad.buttonA.isPressed == true){
            print("buttonA pressed")
            self.goFish()
          } else if ( gamepad.buttonA.isPressed == false) {
            print("buttonA released")
          }
        } else if ( gamepad.buttonY == element) {
          if ( gamepad.buttonY.isPressed == true){
            print("buttonY pressed")
          } else if ( gamepad.buttonY.isPressed == false) {
            print("buttonY released")
          }
        } else if ( gamepad.buttonB == element) {
          if ( gamepad.buttonB.isPressed == true){
            print("buttonB pressed")
            self.bashFish()
          } else if ( gamepad.buttonB.isPressed == false) {
            print("buttonB released")
          }
        } else if ( gamepad.buttonX == element) {
          if ( gamepad.buttonX.isPressed == true){
            print("buttonX pressed")
          } else if ( gamepad.buttonX.isPressed == false) {
            print("buttonX released")
          }
        }
      }
    }
    
#if os(tvOS)
    func setupMicroController(_ controller: GCController) {
      print("Setting up micro controller aka tv remote.")
      controller.microGamepad?.valueChangedHandler = {
        (gamepad:GCMicroGamepad, element:GCControllerElement) in
        gamepad.reportsAbsoluteDpadValues = true
        gamepad.allowsRotation = true
        if ( gamepad.buttonX == element) {
          
          if (gamepad.buttonX.isPressed == true){
            //Button X is the play / pause button on the new Apple TV remote
            print("isPressed buttonX on the microGamepad")
          } else if (gamepad.buttonX.isPressed == false ){
            print("released buttonX on the microGamepad")
          }
        } else if ( gamepad.buttonA == element) {
          //Button A is usually activated by a harder press on the touchpad.
          if (gamepad.buttonA.isPressed == true){
            print("isPressed buttonA on the microGamepad")
          } else if (gamepad.buttonA.isPressed == false ){
            print("released buttonA on the microGamepad")
          }
        }
        else if (gamepad.dpad == element) {
          if (gamepad.dpad.right.value > 0.1) {
            print("isPressed right")
          } else if (gamepad.dpad.right.value == 0.0) {
            print("released right")
          }
          if (gamepad.dpad.left.value > 0.1) {
            print("isPressed left")
          } else if (gamepad.dpad.left.value == 0.0) {
            print("released left")
          }
        }
      }
    }
#endif
  }
}
#endif
