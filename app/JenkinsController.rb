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
        @feed = BW::JSON.parse(r.body)['jobs']
        reload_data
      elsif r.status_code.to_s =~ /40\d/
        show_alert("Failed to fetch data", "Jenkins is down or your settings are wrong. Please check.")
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
    @statusItem.setImage(failure_jobs_exist? ? failure_image : success_image)
    unless @feed.empty?
      @menu.addItem NSMenuItem.separatorItem
      @feed.each do |job|
        menu_item = @menu.addItemWithTitle("#{job['name']} - #{job['color']}", action: "link_item_url:", keyEquivalent:'')
        menu_item.setTarget(self)
      end
    end

    @menu.addItem NSMenuItem.separatorItem
    settings_item = @menu.addItemWithTitle('Settings', action: 'settings:', keyEquivalent: '')
    settings_item.setTarget(self)
    @menu.addItemWithTitle("Quit #{App.name}", action: 'terminate:', keyEquivalent: 'q')
  end

  def link_item_url(sender)
    item = @feed[@menu.indexOfItem(sender)]
    NSWorkspace.sharedWorkspace.openURL(target_url(item))
  end

  def refresh_status(sender)
    fetchStatus
  end

  # table delegate

  def numberOfRowsInTableView(aTableView)
    @feed.size
  end

  def tableView(aTableView,
                objectValueForTableColumn: aTableColumn,
                row: rowIndex)
    id = aTableColumn.identifier
    case id
      when "name"
        @feed[rowIndex][id]
      when "color"
        @feed[rowIndex][id]
    end
  end

  def tableView(tableView, willDisplayCell: cell, forTableColumn: column, row: row)
    if column.identifier == "color"
      color = case cell.stringValue
        when "red"
          NSColor.redColor
        when "blue"
          NSColor.blueColor
        else
          NSColor.grayColor
      end
      cell.setTextColor(color)
    end
  end

  def settings(sender)
    @mySettingsController ||= SettingsController.alloc.init

    # ask our edit sheet for information on the record we want to add
    newValues = @mySettingsController.edit(currentValues, from:self)
    if !@mySettingsController.wasCancelled
      NSUserDefaults.standardUserDefaults.setObject(newValues["jenkins_url"], forKey:"jenkins_url") if newValues["jenkins_url"]
    end
  end

  def refresh(sender)
    fetchStatus
  end

  private

    def target_url(item)
      # Replace base url
      NSURL.URLWithString(item['url'].gsub(%r{^https?://[^/]+/}, jenkins_base_url))
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
      @feed.any?{|job| job['color'] == 'red' }
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
end
