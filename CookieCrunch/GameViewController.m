//
//  GameViewController.m
//  CookieCrunch
//
//  Created by shi qing on 15/3/30.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"

#import "Level.h"

@interface GameViewController()

@property (strong, nonatomic) Level *level;
@property (strong, nonatomic) GameScene *scene;

// Below properties is for the score
@property (assign, nonatomic) NSUInteger movesLeft;
@property (assign, nonatomic) NSUInteger score;

@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *gameOverPanel;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation SKScene (Unarchive)

+ (instancetype)unarchiveFromFile:(NSString *)file {
    /* Retrieve scene file path from the application bundle */
    NSString *nodePath = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];
    /* Unarchive the file to an SKScene object */
    NSData *data = [NSData dataWithContentsOfFile:nodePath
                                          options:NSDataReadingMappedIfSafe
                                            error:nil];
    NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [arch setClass:self forClassName:@"SKScene"];
    SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    [arch finishDecoding];
    
    return scene;
}

@end

@implementation GameViewController

// This is the main method 
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.multipleTouchEnabled = NO;
    
    // Create and configure the scene.
    // before use this not work - sceneWithSize:skView.bounds.size
    self.scene = [GameScene unarchiveFromFile:@"GameScene"];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Load the level
    self.level = [[Level alloc] initWithFile:@"Level_1"];
    self.scene.level = self.level;
    [self.scene addTiles];
    
    // Add the handler here for the swap
    id block = ^(Swap *swap) {
        // During the swap animation, disable all other user interaction 
        self.view.userInteractionEnabled = NO;
        
        if ([self.level isPossibleSwap:swap]) {
            // Update _cookies
            [self.level performSwap:swap];
            // Then animate
            [self.scene animateSwap:swap completion:^{
                [self handleMatches];
            }];
        } else {
            [self.scene animateInvalidSwap:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
        }
        
    };
    self.scene.swapHandler = block;
    
    // Present the scene.
    self.gameOverPanel.hidden = YES;
    [skView presentScene:self.scene];
    
    // Start the game
    [self beginGame];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) beginGame {
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    
    [self shuffle];
}

- (void) shuffle {
    NSSet *set = [self.level shuffle];
    [self.scene addSpriteForCookies:set];
}

- (void) handleMatches {
    // Update the model
    NSSet *chains = [self.level removeMatches];
    
    // End situation
    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    
    // Update the view
    [self.scene animateMatchedCookies:chains completion:^{
        // Update the score
        for (Chain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        // Fill holes
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingCookies:columns completion:^{
            // Create new cookies
            NSArray *columns = [self.level topUpCookies];
            [self.scene animateNewCookies:columns completion:^{
                // We need to recursive call this to do the cascade
                [self handleMatches];
            }];
        }];
    }];
}

- (void) beginNextTurn {
    // We need to update the possbileSwaps attribute in the level when we done with a handleMatch
    [self.level detectPossibleSwaps];
    self.view.userInteractionEnabled = YES;
    [self decreamentMoves];
}

- (void) updateLabels {
    self.targetLabel.text = [NSString stringWithFormat:@"%lu", (long)self.level.targetScore];
    self.movesLabel.text = [NSString stringWithFormat:@"%lu", (long)self.movesLeft];
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)self.score];
}

- (void) decreamentMoves {
    self.movesLeft--;
    [self updateLabels];
    
    // detect whether it's an end
    if (self.score >= self.level.targetScore) {
        self.gameOverPanel.image = [UIImage imageNamed:@"LevelComplete"];
        [self showGameOver];
    } else if (self.movesLeft == 0) {
        self.gameOverPanel.image = [UIImage imageNamed:@"GameOver"];
        [self showGameOver];
    }
}

- (void) showGameOver {
    self.gameOverPanel.hidden = NO;
    self.view.userInteractionEnabled = NO;
    
    // When tap on the screen hide the game over
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameOver)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void) hideGameOver {
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    self.gameOverPanel.hidden = YES;
    self.scene.userInteractionEnabled = YES;
    
    [self beginGame];
}

@end
