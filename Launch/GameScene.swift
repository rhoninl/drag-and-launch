//
//  GameScene.swift
//  Launch
//
//  Created by 李毓琪 on 2023/10/26.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var scoreLabel: SKLabelNode!
    var resetButton: SKLabelNode!
    var block: SKShapeNode?
    var goal: SKSpriteNode?
    let slingShotCenter = CGPoint(x: 0, y: -300)
    let goalPostion = CGPoint(x: 0, y: 300)
    let maxSlingDistance: CGFloat = 150.0
    let slingshotRadius: CGFloat = 3
    var score: Int = 0
    var isDraggingBlock = false
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.position = CGPoint(x: 0, y: 350)
        scoreLabel.fontSize = 100
        scoreLabel.text = "Drag!"
        addChild(scoreLabel)
        
        resetButton = SKLabelNode(fontNamed: "Arial")
        resetButton.text = "RESET"
        resetButton.fontSize = 24
        resetButton.horizontalAlignmentMode = .right
        resetButton.verticalAlignmentMode = .bottom
        resetButton.name = "resetButton"
        resetButton.position = CGPoint(x: self.size.width/2 + resetButton.frame.minX, y: self.size.height/2 + resetButton.frame.minX)
        addChild(resetButton)

        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        let slingshot = SKShapeNode(circleOfRadius: slingshotRadius)
        slingshot.position = slingShotCenter
        slingshot.fillColor = .gray
        addChild(slingshot)
        
        createGoal(at: goalPostion)
        createBlock(at: slingShotCenter)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        
        switch touchedNode.name {
        case resetButton.name:
            showConfirmationDialog()
        case "confirmButton":
            resetScore()
            hideConfirmationDialog()
        case "cancelButton":
            hideConfirmationDialog()
        case block?.name:
            if block!.frame.contains(location) {
                isDraggingBlock = true
                block!.physicsBody!.isDynamic = false
            }
        default:
            createBlock(at: slingShotCenter)
            createGoal(at: RandLocation())
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isDraggingBlock else { return }
        var location = touch.location(in: self)
        let offset = CGPoint(x: location.x - slingShotCenter.x, y: location.y - slingShotCenter.y)
        let distance = sqrt(offset.x * offset.x + offset.y * offset.y)
        if location.y > slingShotCenter.y {
            location.x = slingShotCenter.x + (offset.x / distance) * maxSlingDistance
            location.y = slingShotCenter.y
        } else if distance > maxSlingDistance {
            location.y = slingShotCenter.y + (offset.y / distance) * maxSlingDistance
            location.x = slingShotCenter.x + (offset.x / distance) * maxSlingDistance
        }
        
        block!.position = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDraggingBlock {
            let dx = slingShotCenter.x - block!.position.x
            let dy = slingShotCenter.y - block!.position.y
            let launchVelocity = CGVector(dx: dx * 1.2, dy: dy * 1.1)
            block!.physicsBody!.isDynamic = true
            block!.physicsBody!.applyImpulse(launchVelocity)
            isDraggingBlock = false
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let block = block, !frame.intersects(block.frame) {
            block.removeFromParent()
            self.block = nil
             
            let ssc = slingShotCenter
            let delayAction = SKAction.wait(forDuration: 0.2)
            let createAction = SKAction.run { [weak self] in
                self?.createBlock(at: ssc)
                self?.createGoal(at: nil)
            }
            self.run(SKAction.sequence([delayAction, createAction]))
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if mask == (PhysicsCategories.block | PhysicsCategories.goal) {
            score += 1
            
            scoreLabel.text = "\(score)"
            self.goal?.removeFromParent()
            self.goal = nil
        }
    }

    
    func createBlock(at position: CGPoint) {
        block?.removeFromParent()
        
        block = SKShapeNode(circleOfRadius: 20)
        block!.position = position
        block!.fillColor = .red
        block!.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        block!.physicsBody?.categoryBitMask = PhysicsCategories.block
        block!.physicsBody?.contactTestBitMask = PhysicsCategories.goal
        block!.physicsBody?.collisionBitMask = 0
        block!.physicsBody!.isDynamic = false
        self.addChild(block!)
    }

    func createGoal(at position: CGPoint?, reset: Bool = false) {
        guard reset || goal == nil else {
            return
        }
        
        var targetPostion = position
        if targetPostion == nil {
            targetPostion = RandLocation()
        }
        
        if goal != nil {
            goal?.removeFromParent()
        }
        
        goal = SKSpriteNode(color: UIColor(red: 0.4, green: 0.4, blue: 0.9, alpha: 0.8), size: CGSize(width: 100, height:10))
        
        goal!.position = targetPostion!
        goal!.physicsBody = SKPhysicsBody(rectangleOf: goal!.size)
        goal!.physicsBody?.categoryBitMask = PhysicsCategories.goal
        goal!.physicsBody?.collisionBitMask = 0
        goal!.physicsBody?.contactTestBitMask = PhysicsCategories.block
        goal!.physicsBody?.isDynamic = false
        self.addChild(goal!)
    }
    
    
    func RandLocation() -> CGPoint {
        let x: Int = Int.random(in: -250...250)
        let y: Int = Int.random(in: 0...400)
        
        return CGPoint(x: x, y: y)
    }
    
    func resetScore() {
        score = 0
        scoreLabel.text = "Drag!"
        createGoal(at: goalPostion, reset: true)
    }
    
    func showConfirmationDialog() {
            let mask = SKShapeNode(rect: self.frame)
            mask.fillColor = UIColor.black.withAlphaComponent(0.5)
            mask.zPosition = 100
            mask.name = "mask"
            addChild(mask)

            let confirmButton = SKLabelNode(fontNamed: "Arial")
            confirmButton.text = "Confirm"
            confirmButton.fontSize = 24
            confirmButton.position = CGPoint(x: 0, y: 30)
            confirmButton.name = "confirmButton"
            mask.addChild(confirmButton)

            let cancelButton = SKLabelNode(fontNamed: "Arial")
            cancelButton.text = "Cancel"
            cancelButton.fontSize = 24
            cancelButton.position = CGPoint(x: 0, y: -30)
            cancelButton.name = "cancelButton"
            mask.addChild(cancelButton)

            let message = SKLabelNode(fontNamed: "Arial")
            message.text = "Are you sure?"
            message.fontSize = 30
            message.position = CGPoint(x: 0, y: 90)
            mask.addChild(message)
        }

        func hideConfirmationDialog() {
            childNode(withName: "mask")?.removeFromParent()
        }
}


struct PhysicsCategories {
    static let block: UInt32 = 0x1 << 1
    static let goal: UInt32 = 0x1 << 2
}
