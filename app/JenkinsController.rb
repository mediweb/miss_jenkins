class JenkinsController < NSWindowController

  attr_reader :window
  attr_reader :menu

  def init
    @feed = []
    super
    buildMenu
    buildWindow
    fetchStatus
    self
  end

  def buildMenu
    width = height = [NSStatusBar.systemStatusBar.thickness, 30.0].min

    statusItem = NSStatusBar.systemStatusBar.statusItemWithLength(NSSquareStatusItemLength).retain
    statusItem.setHighlightMode true

    menu_image = NSImage.imageNamed("MissJenkins.icns")
    menu_image.setSize(NSMakeSize(width, height))
    statusItem.setImage(menu_image)

    @menu = NSMenu.alloc.initWithTitle("MissJenkins")
    statusItem.setMenu(@menu)
  end

  def buildWindow
    scroll_view_height = 320
    @window = NSWindow.alloc.initWithContentRect([[240, 180], [432, scroll_view_height + 70]],
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask,
      backing: NSBackingStoreBuffered,
      defer: false)
    @window.title = NSBundle.mainBundle.infoDictionary['CFBundleName']
    @window.orderFrontRegardless

    scroll_view = NSScrollView.alloc.initWithFrame(NSMakeRect(20, 50, 392, scroll_view_height))
    scroll_view.setAutoresizingMask(NSViewWidthSizable|NSViewHeightSizable)
    scroll_view.setHasVerticalScroller(true)
    scroll_view.setHasHorizontalScroller(true)
    scroll_view.setBorderType(NSBezelBorder)
    @window.contentView.addSubview(scroll_view)

    @myTableView = NSTableView.alloc.init
    @myTableView.setUsesAlternatingRowBackgroundColors(true)
    scroll_view.setDocumentView(@myTableView)

    column_name = NSTableColumn.alloc.initWithIdentifier("name")
    column_name.editable = false
    column_name.headerCell.title = "Name"
    column_name.width = 150
    @myTableView.addTableColumn(column_name)

    column_color = NSTableColumn.alloc.initWithIdentifier("color")
    column_color.editable = false
    column_color.headerCell.title = "Status"
    column_color.width = 150
    @myTableView.addTableColumn(column_color)

    @myTableView.delegate = self
    @myTableView.dataSource = self

    @addButton = NSButton.alloc.initWithFrame(NSMakeRect(337, 13, 80, 28))
    @addButton.setTitle("Settings")
    @addButton.setAction("settings:")
    @addButton.setTarget(self)
    @addButton.setBezelStyle(NSRoundedBezelStyle)
    @addButton.setAutoresizingMask(NSViewMinXMargin)
    @window.contentView.addSubview(@addButton)

    @addButton = NSButton.alloc.initWithFrame(NSMakeRect(247, 13, 80, 28))
    @addButton.setTitle("Refresh")
    @addButton.setAction("refresh:")
    @addButton.setTarget(self)
    @addButton.setBezelStyle(NSRoundedBezelStyle)
    @addButton.setAutoresizingMask(NSViewMinXMargin)
    @window.contentView.addSubview(@addButton)
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
    @myTableView.reloadData
    refresh_menu_items
  end

  def refresh_menu_items
    @menu.removeAllItems
    @feed.each do |job|
      menu_item = @menu.addItemWithTitle("#{job['name']} - #{job['color']}", action: "link_item_url:", keyEquivalent:'')
      menu_item.setTarget(self)
    end
  end

  def link_item_url(sender)
    item = @feed[@menu.indexOfItem(sender)]
    NSWorkspace.sharedWorkspace.openURL(target_url(item))
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
end
