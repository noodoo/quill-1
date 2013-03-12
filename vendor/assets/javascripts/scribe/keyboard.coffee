class ScribeKeyboard
  @KEYS:
    BACKSPACE : 8
    TAB       : 9
    ENTER     : 13
    LEFT      : 37
    UP        : 38
    RIGHT     : 39
    DOWN      : 40
    DELETE    : 46

  @HOTKEYS:
    BOLD:       { key: 'B', meta: true }
    ITALIC:     { key: 'I', meta: true }
    UNDERLINE:  { key: 'U', meta: true }
    UNDO:       { key: 'Z', meta: true, shift: false }
    REDO:       { key: 'Z', meta: true, shift: true }

  @PRINTABLE

  constructor: (@editor) ->
    @hotkeys = {}
    this.initListeners()
    this.initHotkeys()

  initListeners: ->
    @editor.root.addEventListener('keydown', (event) =>
      event ||= window.event
      if @hotkeys[event.which]?
        prevent = false
        _.each(@hotkeys[event.which], (hotkey) =>
          return if hotkey.meta? and event.metaKey != hotkey.meta
          return if hotkey.shift? and event.shiftKey != hotkey.shift
          @editor.selection.update(true)
          selection = @editor.getSelection()
          return unless selection?
          prevent = true
          hotkey.callback.call(null, selection)
        )
      event.preventDefault() if prevent
      return !prevent
    )

  initHotkeys: ->
    this.addHotkey(Scribe.Keyboard.KEYS.TAB, =>
      @editor.selection.deleteRange()
      this.insertText("\t")
    )
    this.addHotkey(Scribe.Keyboard.KEYS.ENTER, =>
      @editor.selection.deleteRange()
      this.insertText("\n")
    )
    #this.addHotkey(Scribe.Keyboard.KEYS.BACKSPACE, (selection) =>
    #  unless @editor.selection.deleteRange()
    #    @editor.deleteAt(selection.start.index - 1, 1) if selection.start.index > 0
    #)
    #this.addHotkey(Scribe.Keyboard.KEYS.DELETE, (selection) =>
    #  unless @editor.selection.deleteRange()
    #    @editor.deleteAt(selection.start.index, 1) if selection.start.index < @editor.getLength() - 1
    #)
    this.addHotkey(Scribe.Keyboard.HOTKEYS.BOLD, (selection) =>
      this.toggleFormat(selection, 'bold')
    )
    this.addHotkey(Scribe.Keyboard.HOTKEYS.ITALIC, (selection) =>
      this.toggleFormat(selection, 'italic')
    )
    this.addHotkey(Scribe.Keyboard.HOTKEYS.UNDERLINE, (selection) =>
      this.toggleFormat(selection, 'underline')
    )

  addHotkey: (hotkey, callback) ->
    hotkey = if _.isObject(hotkey) then _.clone(hotkey) else { key: hotkey }
    hotkey.key = hotkey.key.toUpperCase().charCodeAt(0) if _.isString(hotkey.key)
    hotkey.callback = callback
    @hotkeys[hotkey.key] = [] unless @hotkeys[hotkey.key]?
    @hotkeys[hotkey.key].push(hotkey)

  indent: (selection, increment) ->
    lines = selection.getLines()
    applyIndent = (line, format) =>
      if increment
        indent = if _.isNumber(line.formats[format]) then line.formats[format] else (if line.formats[format] then 1 else 0)
        indent += increment
        indent = Math.min(Math.max(indent, Scribe.Constants.MIN_INDENT), Scribe.Constants.MAX_INDENT)
      else
        indent = false
      index = Scribe.Position.getIndex(line.node, 0)
      @editor.formatAt(index, 0, format, indent)

    _.each(lines, (line) =>
      if line.formats.bullet?
        applyIndent(line, 'bullet')
      else if line.formats.list?
        applyIndent(line, 'list')
      else
        applyIndent(line, 'indent')
      @editor.doc.rebuildDirty()
    )

  onIndentLine: (selection) ->
    return false if !selection?
    intersection = selection.getFormats()
    return intersection.bullet? || intersection.indent? || intersection.list?

  insertText: (text) ->
    selection = @editor.getSelection()
    @editor.insertAt(selection.start.index, text)
    # Make sure selection is after our text
    range = new Scribe.Range(@editor, selection.start.index + text.length, selection.start.index + text.length)
    @editor.setSelection(range)

  toggleFormat: (selection, format) ->
    formats = selection.getFormats()
    @editor.selection.format(format, !formats[format])


window.Scribe or= {}
window.Scribe.Keyboard = ScribeKeyboard