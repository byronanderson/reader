# Actions!
App.viewGroup = (filter, group_id) ->
  tracker.track("View Group Stream");
  App.sorter = App.sorters.publishDate
  group = App.groups.find (group) ->
    (group.get('key') == group_id)

  if group?
    group.view()
    App.hideList()
  else
    App.router.navigate('/', {trigger: true})

App.itemIdClickedFromSummary = null
App.viewSubscription = (filter, subscription_id, item_id) ->
  if item_id?
    tracker.track("View Item from Homepage Summary");
    App.itemIdClickedFromSummary = item_id

  tracker.track("View Subscription Stream");
  App.filter = filter
  App.trigger("change:filter")
  App.sorter = App.sorters.publishDate
  subscription = App.subscriptions.get(subscription_id)
  if subscription?
    subscription.view()
    App.hideList()
  else
    App.router.navigate('/', {trigger: true})

App.viewPerson = (filter, id) ->
  tracker.track("View Person Stream");
  App.filter = filter
  App.trigger("change:filter")
  App.sorter = App.sorters.publishDate
  person = App.people.get(id)
  if person?
    person.view()
    App.hideList()
  else
    App.router.navigate('/', {trigger: true})

App.viewSingleItem = (id) ->
  tracker.track("View Single Item");
  singleItemStream = new App.Stream({name: "", items_url: "/items/#{id}/items.json"})
  singleItemStream.view()

App.viewAll = ->
  tracker.track("View All Items Stream");
  App.filter = "all"
  App.trigger("change:filter")
  App.sorter = App.sorters.publishDate
  App.stream = App.unread
  App.all.view()
  App.router.navigate("/#{App.filter}")

App.viewUnread = ->
  tracker.track("View Unread Items Stream");
  App.filter = "unread"
  App.trigger("change:filter")
  App.sorter = App.sorters.publishDate
  App.stream = App.unread
  App.unread.view()
  App.router.navigate("/#{App.filter}")

App.viewStarred = ->
  tracker.track("View Starred Items Stream");
  App.filter = "starred"
  App.trigger("change:filter")
  App.sorter = App.sorters.updatedAt
  App.stream = App.starred
  App.starred.view()
  App.router.navigate("/#{App.filter}")


App.viewShared = ->
  tracker.track("View Shared Items Stream");
  App.filter = "shared"
  App.trigger("change:filter")
  App.sorter = App.sorters.updatedAt
  App.stream = App.shared
  App.shared.view()
  App.router.navigate("/#{App.filter}")

App.viewCommented = () ->
  tracker.track("View Commented Items Stream");
  App.filter = "commented"
  App.trigger("change:filter")
  App.sorter = App.sorters.lastComment
  App.stream = App.commented
  App.commented.view()
  App.router.navigate("/#{App.filter}")
  $("#nav-comments-link").removeClass("attention")

App.itemLocator = null

App.streamItems = []
App.viewStream = (title, link) ->
  $("a.filter-#{App.filter}").tab('show')
  App.loadMore_loading = false
  App.trigger("set:stream")
  App.itemRenderers = []
  App.showStream()
  stream = $('#stream')
  stream.empty()
  $(document).scrollTop(0)

  _itemsInView = _.first(App.items.toArray(), App.ITEM_SET_SIZE)
  App.streamItems = _.rest(App.items.toArray(), App.ITEM_SET_SIZE)
  App.focusedItem = _.first(App.items.toArray())
  App.viewItems(_itemsInView)
  App.streamTitle.set('title', title)
  App.streamTitle.set('link', link)
  App.streamTitle.setCount(App.stream.count())
  App.streamMenu.render()
  $(document).scrollTop(0)
  App.highlightStreamInFeedList()

App.loadMore_loading = false
App.loadMore = () =>
  return if App.loadMore_loading
  App.loadMore_loading = true
  App.stream.loadItems (items) =>
    models = []
    for item in items
      has = App.items.get(item.id)
      unless has?
        item = new App.Item(item)
        App.items.add item
        models.push item
    App.loadMore_loading = false if items.length > 0
    App.viewItems(models)


App.viewMore = () ->
  _itemsInView = _.first(App.streamItems, App.ITEM_SET_SIZE)
  App.streamItems = _.rest(App.streamItems, App.ITEM_SET_SIZE)
  App.viewItems(_itemsInView)

App.viewItems = (_items) ->
  _items.forEach (item) ->
    container = document.createElement('div')
    $('#stream').append(container)
    _entryView = new App.ItemView
        model: item
        id: 'item-' + item.get('id')
        el: container
    _entryView.render()
    App.itemRenderers.push(_entryView)

App.viewPreviousStream = () ->
  $(document).scrollTop(0)
  strm = App.stream
  if strm?
    prev = strm.prev()
    pc = prev.count()
    while pc == 0 && prev != strm
      prev = prev.prev()
      pc = prev.count()
    if prev?
      prev.view()
      App.router.navigate(prev.path())
      window.setTimeout(() ->
        $(document).off 'mousewheel', 'body', App.lockStreamScroll
      , 500)
    else
      App.router.navigate('/', {trigger: true})

App.viewNextStream = () ->
  $('div.item-container').remove()
  $(document).scrollTop(0)
  strm = App.stream
  if strm?
    next = strm.next()
    nc = next.count()
    while nc == 0 && next != strm
      next = next.next()
      nc = next.count()
    if next?
      next.view()
      App.router.navigate(next.path())
      window.setTimeout(() ->
        $(document).off 'mousewheel', 'body', App.lockStreamScroll
      , 500)
    else
      App.router.navigate('/', {trigger: true})

App.markStreamAsRead = () ->
  strm = App.stream
  if strm?
    if strm.subscriptions?
      _(strm.subscriptions()).each (sub) =>
        sub.set("unread_count", 0)

    strm.set("unread_count", 0)
    $.post('/mark_read', {streamType: strm.streamType, id: strm.id}, (data, status, xhr) ->
      App.renderFeedList()
    )
    next = strm.next()
    if next?
      next.view()
      window.setTimeout(() ->
        $(document).off 'mousewheel', 'body', App.lockStreamScroll
      , 500)
    else
      App.router.navigate('/', {trigger: true})

