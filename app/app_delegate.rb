class AppDelegate
  def applicationDidFinishLaunching(notification)
    buildMenu
    @jenkinsController = JenkinsController.alloc.init
  end
end
