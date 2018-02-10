//
//  GameScene.swift
//  Flappy Bird
//
//  Created by 勝良祥吾 on 2018/02/08.
//  Copyright © 2018年 shougo.katsura. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var itemNode: SKNode!
    var bird: SKSpriteNode!
    
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemScoreCategory: UInt32 = 1 << 4
    
    var itemScore = 0
    
    var score = 0
    var scoreLabelNode: SKLabelNode!
    var itemScoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    let userDefaults: UserDefaults = UserDefaults.standard
    
    let sound = SKAction.playSoundFileNamed("kirakira", waitForCompletion: false)

    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red: 0.15, green: 0.78, blue: 0.90, alpha: 0.5)
        
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        setupGround()
        setupClouwd()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()
            
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        
        } else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
            itemScore += 1
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            itemScoreLabelNode.text = "ItemScore:\(itemScore)"
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
            contact.bodyB.node?.removeFromParent()
            self.run(sound)
            
        } else {
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            bird.physicsBody?.velocity = CGVector.zero
            
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
        
        bird.physicsBody?.velocity = CGVector.zero
        
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
    }
    
    func setupGround(){
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5.0)
        
        let resetGround = SKAction.moveBy(x: groundTexture.size().width , y: 0, duration: 0.0)
        
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            sprite.position = CGPoint(x: groundTexture.size().width * (CGFloat(i) + 0.5), y: groundTexture.size().height * 0.5)
            
            sprite.run(repeatScrollGround)
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            sprite.physicsBody?.isDynamic = false
            
            scrollNode.addChild(sprite)
        }
    }
    
    func setupItem() {
        let itemTexture = SKTexture(imageNamed: "star rate")
        itemTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        let removeItem = SKAction.removeFromParent()
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        let createItemAnimation = SKAction.run({
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            item.zPosition = -51
            
            let center_y = self.frame.size.height / 2
            let random_y_range = self.frame.size.height / 4
            let under_item_lowest_y = UInt32( center_y - itemTexture.size().height / 2 - random_y_range / 2)
            let random_y = arc4random_uniform( UInt32(random_y_range))
            let under_item_y = CGFloat(under_item_lowest_y + random_y)
            
            let star = SKSpriteNode(texture: itemTexture)
            star.position = CGPoint(x: 0.0, y: under_item_y)
            star.physicsBody = SKPhysicsBody(circleOfRadius: star.size.height / 2.0)
            star.physicsBody?.categoryBitMask = self.itemScoreCategory
            star.physicsBody?.contactTestBitMask = self.birdCategory
            star.physicsBody?.isDynamic = false
            item.addChild(star)
            
            item.run(itemAnimation)
            self.itemNode.addChild(item)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 3.2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation,waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
        
    }
    
    func setupClouwd() {
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        let resetCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
            
            sprite.position = CGPoint(x: cloudTexture.size().width * (CGFloat(i) + 0.5), y: self.size.height - cloudTexture.size().height * 0.5)
            
            sprite.run(repeatScrollCloud)
            scrollNode.addChild(sprite)
        }
        
    }
    
    func setupWall() {
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        let removeWall = SKAction.removeFromParent()
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        let createWallAnimation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0
            
            let center_y = self.frame.size.height / 2
            let random_y_range = self.frame.size.height / 4
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 - random_y_range / 2)
            let random_y = arc4random_uniform( UInt32(random_y_range))
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            let slit_length = self.frame.size.height / 6
            
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false
            wall.addChild(under)
        
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false
            wall.addChild(upper)
            
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
        
    }
    
    func setupBird() {
        
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        bird.run(flap)
        
        addChild(bird)
    }
    
    func restart() {
        score = 0
        itemScore = 0
        scoreLabelNode.text = String("Score\(score)")
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    
    
    
    
}
