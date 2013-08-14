class AppDelegate
  def applicationDidFinishLaunching(notification)
    buildMenu
    @jenkinsController = JenkinsController.alloc.init
    trigger_refresh
  end

  def trigger_refresh
    timer = NSTimer.timerWithTimeInterval(5*60, target:@jenkinsController, selector:'refresh_status:', userInfo:nil, repeats:true)
    NSRunLoop.mainRunLoop.addTimer(timer, forMode:NSRunLoopCommonModes)
  end
end
