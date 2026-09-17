#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) WKWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 与游戏页面深色背景一致
    UIColor *bg = [UIColor colorWithRed:0.063 green:0.078 blue:0.110 alpha:1.0];
    self.view.backgroundColor = bg;

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    // 注：mediaTypesRequiringUserAction 在新版 SDK（Xcode 26+）中已被 Apple 移除，
    // 本游戏无 <audio>/<video> 元素（音效由 WebAudio 合成），无需设置媒体自动播放策略。

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = bg;
    // 禁止 WebView 内部滚动/回弹/缩放，由页面自身适配
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.bounces = NO;
    self.webView.scrollView.minimumZoomScale = 1.0;
    self.webView.scrollView.maximumZoomScale = 1.0;
    self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.webView.scrollView.delegate = self;
    [self.view addSubview:self.webView];

    // 加载打包在 App 内的游戏页面
    NSURL *pageURL = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:@"www"];
    [self.webView loadFileURL:pageURL allowingReadAccessToURL:[pageURL URLByDeletingLastPathComponent]];
}

// 禁止捏合缩放
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

// 全屏沉浸：隐藏状态栏与底部小横条
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

@end
