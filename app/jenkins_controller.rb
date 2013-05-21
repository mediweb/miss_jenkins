class JenkinsController < NSWindowController
  attr_reader :window

  def init
    super
    buildWindow
    @feed = []

    @table_view = NSTableView.alloc.init
    column_name = NSTableColumn.alloc.initWithIdentifier("name")
    column_name.editable = false
    column_name.headerCell.title = "Name"
    column_name.width = 150
    @table_view.addTableColumn(column_name)

    column_color = NSTableColumn.alloc.initWithIdentifier("color")
    column_color.editable = false
    column_color.headerCell.title = "Status"
    column_color.width = 150
    @table_view.addTableColumn(column_color)

    @table_view.delegate = self
    @table_view.dataSource = self
    @window.contentView.addSubview(@table_view)

    fetchStatus
    self
  end

  def buildWindow
    @window = NSWindow.alloc.initWithContentRect([[240, 180], [480, 360]],
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask,
      backing: NSBackingStoreBuffered,
      defer: false)
    @window.title = NSBundle.mainBundle.infoDictionary['CFBundleName']
    @window.orderFrontRegardless
  end

  def fetchStatus
    BW::HTTP.get('http://jenkins.local:8088/api/json') do |r|
      @feed = BW::JSON.parse(r.body)['jobs']
      @table_view.reloadData
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
end
