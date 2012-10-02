Typeahead
=========

An extension of Twitter's Bootstrap Typeahead plugin


Example Usage
=========

```
$(@el).find('.search').typeahead {
  ajax:
    url: "http://api.mydomain.com"
    method: 'get'
    timeout: 0
    trigger: 1
    before: (query) ->
      return {q: query, ref: 'typeahead'}
    after: (data) ->
      if typeof data == 'string'
        data = JSON.parse data
      results = []
      for item in data.items
        item._label = item.name
        item._type = item.type
        results.push item
      results.push {
        _label: "See more results for '#{data.query}'..."
        _type: 'more'
        query: data.query
      }
      results
  label: '_label'
  menu: '<ul id="search-dropdown" class="typeahead dropdown-menu search-dropdown"></ul>'
  item: (item) ->
    item.icon = ''
    switch item._type
      when 'song'   then item.icon = 'icon-music'
      when 'video'  then item.icon = 'icon-film'
      when 'artist' then item.icon = 'icon-user-md'
      when 'user'   then item.icon = 'icon-user'

    "
      <li class='search-dropdown-entry'>
        <i class='#{item.icon}'></i>
        <a class='ellipsis' href='#'></a>
      </li>
    "
  onSelect: (item) =>
    if item and item._type == 'more'
      $(@el).find('.search').val item.query
      item = null

    if item
      switch item._type
        when 'user'
          go "/user/#{item.slug}"
        when 'track', 'video'
          player.similar item
        when 'artist', 'label'
          go "/#{item.slug}"
    else
      val = $(@el).find('.search').val()
      if val.length == 0
        app.search.close()
      else
        app.search.render val
    $(@el).find('.search').val ''
    return true
  size: 10
  sort: (query, items) ->
    beginswith = []
    caseSensitive = []
    caseInsensitive = []
    seeMore = []

    while (item = items.shift())
      if item._label[0...16] == 'See more results'
        seeMore.push item
      else if not item._label.toLowerCase().indexOf query.toLowerCase()
        beginswith.push item
      else if ~item._label.indexOf query
        caseSensitive.push item
      else
        caseInsensitive.push item
    items = beginswith.concat caseSensitive, caseInsensitive
    items = items.slice 0, 9 if seeMore.length > 0
    items.concat seeMore
}
```
