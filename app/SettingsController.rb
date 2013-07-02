class SettingsController < NSWindowController
  attr_reader :window

  def init
    super
    buildPanel
    self
  end

  def buildPanel
    @window = NSWindow.alloc.initWithContentRect([[0, 0], [280, 140]],
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask,
      backing: NSBackingStoreBuffered,
      defer: false)
    @window.title = "Settings"
    @window.orderFrontRegardless
    @window.center

    @editForm = NSForm.alloc.initWithFrame(NSMakeRect(13, 48, 242, 73))
    @editForm.setAutoresizingMask(NSViewMaxYMargin|NSViewWidthSizable)
    @editForm.setCellSize(NSMakeSize(242, 19))
    editForm_url_cell = @editForm.addEntry("jenkins_url")
    editForm_url_cell.setTitle("URL:")
    @editForm.setKeyCell(editForm_url_cell)
    @window.contentView.addSubview(@editForm)

    cancelButton = NSButton.alloc.initWithFrame(NSMakeRect(102, 13, 80, 28))
    cancelButton.setTitle("Cancel")
    cancelButton.setAction("cancel:")
    cancelButton.setTarget(self)
    cancelButton.setBezelStyle(NSRoundedBezelStyle)
    cancelButton.setAutoresizingMask(NSViewMinXMargin)
    @window.contentView.addSubview(cancelButton)

    okButton = NSButton.alloc.initWithFrame(NSMakeRect(180, 13, 80, 28))
    okButton.setTitle("OK")
    okButton.setAction("done:")
    okButton.setTarget(self)
    okButton.setBezelStyle(NSRoundedBezelStyle)
    okButton.setAutoresizingMask(NSViewMinXMargin)
    @window.contentView.addSubview(okButton)
  end

  def edit(startingValues, from:sender)
    window = self.window

    @cancelled = false

    editFields = @editForm.cells
    if startingValues
      # we are editing current entry, use its values as the default
      @savedFields = startingValues
      editFields.objectAtIndex(0).setStringValue(startingValues["jenkins_url"])
    else
      # we are adding a new entry,
      # make sure the form fields are empty due to the fact that this controller is recycled
      # each time the user opens the sheet -
      editFields.objectAtIndex(0).setStringValue("")
    end

    NSApp.beginSheet(window, modalForWindow:sender.window, modalDelegate:nil, didEndSelector:nil, contextInfo:nil)
    NSApp.runModalForWindow(window)
    # sheet is up here...

    NSApp.endSheet(window)
    window.orderOut(self)

    @savedFields
  end

  def done(sender)
    # save the values for later
    editFields = @editForm.cells

    @savedFields = {
      "jenkins_url" => editFields.objectAtIndex(0).stringValue,
    }

    NSApp.stopModal
  end

  def cancel(sender)
    NSApp.stopModal
    @cancelled = true
  end

  def wasCancelled
    @cancelled
  end
end
