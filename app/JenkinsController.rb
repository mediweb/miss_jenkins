class JenkinsController < NSWindowController
  attr_reader :window

  def init
    @feed = []
    super
    buildWindow
    fetchStatus
    self
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
    BW::HTTP.get('http://jenkins.local:8088/api/json') do |r|
      @feed = BW::JSON.parse(r.body)['jobs']
      @myTableView.reloadData
    end
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
    newValues = @mySettingsController.edit(nil, from:self)
    if !@mySettingsController.wasCancelled
      # TODO save settings
      puts "Saving settings #{newValues}"
    end
  end

  def refresh(sender)
    fetchStatus
  end
end
