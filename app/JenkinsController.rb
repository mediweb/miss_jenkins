class JenkinsController < NSWindowController

  attr_reader :window
  attr_reader :menu

  def init
    @feed = []
    super
    buildMenu
    fetchStatus
    self
  end

  def buildMenu
    @statusItem = NSStatusBar.systemStatusBar.statusItemWithLength(NSSquareStatusItemLength).retain
    @statusItem.setHighlightMode true

    @statusItem.setImage(default_image)

    @menu = NSMenu.alloc.initWithTitle("MissJenkins")
    @statusItem.setMenu(@menu)
  end

  def fetchStatus
    BW::HTTP.get(jenkins_base_url + 'api/json') do |r|
      if r.ok?
        @feed = BW::JSON.parse(r.body)['jobs'].group_by{|job| job['color']}
        reload_data
      elsif r.status_code.to_s =~ /40\d/
        show_alert("Failed to fetch data", "Jenkins is down or your settings are wrong. Please check.")
        settings(nil)
      else
        show_alert("Error", r.error_message)
      end
    end
  end

  def reload_data
    refresh_menu_items
  end

  def refresh_menu_items
    @menu.removeAllItems
    refresh_item = @menu.addItemWithTitle("Refresh", action: "refresh_status:", keyEquivalent:'')
    refresh_item.setTarget(self)
    refresh_item.setImage(image_by_type('refresh'))
    @statusItem.setImage(failure_jobs_exist? ? failure_image : success_image)

    ordered_status = ["red_anime", "blue_anime", "grey_anime", "disabled_anime", "red", "blue", "grey", "disabled"]
    (ordered_status & @feed.keys).each do |color|
      @menu.addItem NSMenuItem.separatorItem
      @feed[color].each do |job|
        menu_item = @menu.addItemWithTitle("#{job['name']} - #{job['color']}", action: "link_item_url:", keyEquivalent:'')
        menu_item.setTarget(self)
        menu_item.setImage(image_by_type(color))
      end
    end

    @menu.addItem NSMenuItem.separatorItem
    settings_item = @menu.addItemWithTitle('Settings', action: 'settings:', keyEquivalent: '')
    settings_item.setTarget(self)
    settings_item.setImage(image_by_type('settings'))
    quit_item = @menu.addItemWithTitle("Quit #{App.name}", action: 'terminate:', keyEquivalent: 'q')
    quit_item.setImage(image_by_type('quit'))
  end

  def link_item_url(sender)
    item = @feed[@menu.indexOfItem(sender)]
    NSWorkspace.sharedWorkspace.openURL(target_url(item))
  end

  def refresh_status(sender)
    fetchStatus
  end

  def settings(sender)
    @mySettingsController ||= SettingsController.alloc.init

    # ask our edit sheet for information on the record we want to add
    newValues = @mySettingsController.edit(currentValues, from:self)
    if !@mySettingsController.wasCancelled
      NSUserDefaults.standardUserDefaults.setObject(newValues["jenkins_url"], forKey:"jenkins_url") if newValues["jenkins_url"]
    end
  end

  private

    def target_url(item)
      # Replace base url
      NSURL.URLWithString(item['url'])
    end

    def jenkins_base_url
      NSUserDefaults.standardUserDefaults.stringForKey("jenkins_url") || 'http://127.0.0.1:8080/'
    end

    def currentValues
      {"jenkins_url" => jenkins_base_url}
    end

    def show_alert(title, message)
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle("OK")
      alert.setMessageText(title)
      alert.setInformativeText(message)
      alert.setAlertStyle(NSCriticalAlertStyle)
      alert.beginSheetModalForWindow(@window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
    end

    def failure_jobs_exist?
      @feed.map{|status, jobs| jobs }.flatten.any?{|job| job['color'] == 'red' }
    end

    # Images
    def default_image
      success_image
    end

    def success_image
      @success_image ||= NSImage.imageNamed("MissJenkins.icns")
      @success_image.setSize(NSMakeSize(image_width, image_height))
      @success_image
    end

    def failure_image
      # TODO replace image with MissJenkins_failure.icns
      @failure_image ||= NSImage.imageNamed("MissJenkins.icns")
      @failure_image.setSize(NSMakeSize(image_width, image_height))
      @failure_image
    end

    def image_width
      [NSStatusBar.systemStatusBar.thickness, 30.0].min
    end

    def image_height
      image_width
    end

    def image_by_type(type)
      # TODO rename images to "#{type}_icon&16.png" will be better
      # TODO change color of icon images
      NSImage.imageNamed case type
      when /^red/
        'delete_icon&16.png'
      when /^blue/
        'checkmark_icon&16.png'
      when 'settings'
        'cog_icon&16.png'
      when 'refresh'
        'reload_icon&16.png'
      when 'quit'
        'on-off_icon&16.png'
      else
        'cancel_icon&16.png'
      end
    end
end
