//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Lucas Simon on 6/24/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_scroller;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    CCNode *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
}

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
    _physicsNode.collisionDelegate = self;
}

-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_scroller];
    
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        [self setMousePositionX:touchLocation.x Y:touchLocation.y];
        
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
        
        _currentPenguin = [CCBReader load:@"Penguin"];
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        [_physicsNode addChild:_currentPenguin];
        _currentPenguin.physicsBody.allowsRotation = FALSE;
        
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
    }
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchLocation = [touch locationInNode:_scroller];
    [self setMousePositionX:touchLocation.x Y:touchLocation.y];
}

- (void)setMousePositionX:(float)x Y:(float)y {
    _mouseJointNode.position = ccp(x,y);
}

-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self releaseCatapult];
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self releaseCatapult];
}

- (void)releaseCatapult {
    if (_mouseJoint != nil)
    {
        [_mouseJoint invalidate];
        _mouseJoint = nil;
    }
    
    [_penguinCatapultJoint invalidate];
    _penguinCatapultJoint = nil;
    
    _currentPenguin.physicsBody.allowsRotation = TRUE;
    
    CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
    [_scroller runAction:follow];
}

- (void)launchPenguin {
    CCNode* penguin = [CCBReader load:@"Penguin"];
    penguin.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    [_physicsNode addChild:penguin];
    
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
    
    self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    [_scroller runAction:follow];
}

- (void)retry {
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB {
    float energy = [pair totalKineticEnergy];
    
    // if energy is large enough, remove the seal
    if (energy > 5000.f) {
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        } key:nodeA];
    }
}

- (void)sealRemoved:(CCNode *)seal {
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    explosion.autoRemoveOnFinish = TRUE;
    explosion.position = seal.position;
    [seal.parent addChild:explosion];
    [seal removeFromParent];
}

@end
