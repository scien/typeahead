class Typeahead
  constructor: (elem, options) ->
    @el = $ elem
    @el._typeahead = this
    @options = $.extend true, {}, @defaults, options
    @menu = $(@options.menu).appendTo 'body'
    @shown = false

    # overrides
    @grep       = @options.grep or @grep
    @highlight  = @options.highlight or @highlight
    @search     = @options.search or @search
    @match      = @options.match or @match
    @render     = @options.render or @render
    @select     = @options.select or @select
    @sort       = @options.sort or @sort
    @source     = @options.source or @source

    if options.ajax
      ajax = options.ajax
      if typeof ajax == 'string'
        @ajax = $.extend {}, @defaults.ajax, {url: ajax}
      else
        @ajax = $.extend {}, @defaults.ajax, ajax
      @ajax = null if not @ajax.url
    @listen()
    
  defaults:
    source: []
    items: []
    size: 10
    menu: '<ul class="typeahead dropdown-menu"></ul>'
    item: '<li><a href="#"></a></li>'
    label: 'name'
    onSelect: null
    ajax:
      url: null
      timeout: 300
      method: 'get'
      trigger: 3
      loadingClass: null
      before: null
      after: null

  #
  # Events
  #
  listen: ->
    @el.on 'blur',      $.proxy @blur, @
    @el.on 'keypress',  $.proxy @keypress, @
    @el.on 'keyup',     $.proxy @keyup, @

    if $.browser.webkit or $.browser.msie or $.browser.chrome
      @el.on 'keydown', $.proxy @keypress, @

    @menu.on 'click', $.proxy @click, @
    @menu.on 'mouseover', 'li', $.proxy @mouseover, @
    @menu.on 'mouseout', 'li', $.proxy @mouseout, @

  keyup: (e)->
    e.stopPropagation()
    e.preventDefault()
    switch e.keyCode
      when 40, 38 then return     # up/down
      when 9, 13  then @select()  # tab/enter
      when 27     then @hide()    # escape
      else        @search()

  keypress: (e) ->
    e.stopPropagation()

    switch e.keyCode
      when 9, 13, 27 then e.preventDefault() # tab, enter, escape
      when 38 # up arrow
        if not e.shiftKey
          e.preventDefault()
          @prev()
      when 40 # down arrow
        if not e.shiftKey
          e.preventDefault()
          @next()

  blur: (e) ->
    e.stopPropagation()
    e.preventDefault()
    fn = => @hide()
    setTimeout fn, 150

  click: (e) ->
    e.stopPropagation()
    e.preventDefault()
    @select()

  mouseover: (e) ->
    @menu.find('.active').removeClass 'active'
    $(e.currentTarget).addClass 'active'

  mouseout: (e) ->
    @menu.find('.active').removeClass 'active'

  #
  # Data Fetching
  #
  ajaxCancel: ->
    if @ajax.timer_id
      clearTimeout @ajax.timer_id
      @ajax.timer_id = null

    # Cancel the ajax callback if in progress
    if @ajax.xhr
      @ajax.xhr.abort()
      @ajax.xhr = null
      @loading false
      return true

  ajaxSend: (query) ->
    @loading true
    params = @ajax.before?(query) or {query: query}
    @ajax.xhr = $.ajax {
      url: @ajax.url
      method: @ajax.method
      data: params
      success: $.proxy @ajaxReceive, @
      dataType: 'json'
    }
    @ajax.timerId = null
    
  ajaxReceive: (data) =>
    @loading false

    return if not @ajax.xhr
    @ajax.xhr = null

    (data = @ajax.after data) if @ajax.after
    @source = data
    @items = @grep(data).slice 0, @options.size + 1
    if @items.length then @render @items else @hide()
  
  loading: (show) ->
    @el.toggleClass @ajax.loadingClass, show if @ajax.loadingClass

  search: (e) =>
    return @ if @el.val() == @query
    @query = @el.val()
    return @hide() if not @query

    @items = @grep(@source).slice 0, @options.size + 1
    @render @items

    if @ajax
      @ajaxCancel()
      if @query and @query.length >=  @ajax.trigger
        fn = => $.proxy @ajaxSend @query, @
        @ajax.timerId = setTimeout fn, @ajax.timeout
    return @

  #
  # Handle Results
  #
  grep: (data) ->
    @sort @query, $.grep data, (item) => @match @query, item

  match: (query, item) ->
    ~item[@options.label].toLowerCase().indexOf query.toLowerCase()

  sort: (query, items) ->
    beginswith = []
    caseSensitive = []
    caseInsensitive = []

    while (item = items.shift())
      if not item[@options.label].toLowerCase().indexOf query.toLowerCase()
        beginswith.push item
      else if ~item[@options.label].indexOf query
        caseSensitive.push item
      else
        caseInsensitive.push item
    beginswith.concat caseSensitive, caseInsensitive

  #
  # Dom Manipulation
  #
  show: () ->
    pos = $.extend {}, @el.offset(), {
      height: @el[0].offsetHeight
    }
    @menu.css {
      top: pos.top + pos.height
      left: pos.left
    }
    @menu.show()
    @shown = true
    @

  hide: () ->
    @menu.hide()
    @shown = false
    @
        
  highlight: (item) ->
    query = @query.replace /[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&'
    item.replace new RegExp("(#{query})", 'ig'), ($1, match) ->
      "<strong>#{match}</strong>"

  render: (items) ->
    items = $(items).map (i, item) =>
      el = $(@options.item) if typeof @options.item == 'string'
      el = $(@options.item item) if typeof @options.item == 'function'
      el.find('a').html @highlight item[@options.label]
      el[0]

    @menu.html items
    @show()

  select: () ->
    el = @menu.find '.active'
    index = -1
    while el.length
      index++
      el = el.prev()
    if index == -1
      return if not @options.onSelect null
    else
      val = @menu.find('.active').text()
      val = val.replace /^\s+|\s+$/g, ''
      @el.val(val).change()
      return if not @options.onSelect @items[index]
    @ajaxCancel()
    @hide()

  next: (event) ->
    current = @menu.find('.active').removeClass 'active'
    if not current.length
      $(@menu.find('li')[0]).addClass 'active'
    else
      next = current.next().addClass 'active'
      if not next
        $(@menu.find('li')[0]).addClass 'active' if not next

  prev: (event) ->
    current = @menu.find('.active').removeClass 'active'
    if not current.length
      @menu.find('li').last().addClass 'active'
    else
      prev = current.prev().addClass 'active'
      if not prev
        @menu.find('li').last().addClass 'active'

$.fn.typeahead = (option) ->
  return this.each () ->
    $this = $(this)
    data = $this.data('typeahead')
    options = typeof option == 'object' and option
    
    if not data
      $this.data 'typeahead', (data = new Typeahead(this, options))
    if typeof option == 'string'
        data[option]()

$ ->
  $('body').on 'focus.typeahead.data-api', '[data-provide="typeahead"]', (e) ->
    $this = $(this)
    return if $this.data 'typeahead'
    e.preventDefault()
    $this.typeahead $this.data()


