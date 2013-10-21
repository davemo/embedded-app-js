class window.ShopifyApp
  @debug: false
  @forceRedirect: true
  @apiKey: ""
  @shopOrigin: ""

  @setWindowLocation: (location) -> window.location = location
  @getWindowLocation: -> window.location
  @getWindowParent:   -> window.parent

  @ready: (fn) ->
    ShopifyApp.__addMessageHandler "Shopify.API.initialize", fn

  @init: (config={}) ->
    @loadConfig(config)
    @checkFrame()

    # Write our own listeners using the pattern we provide.
    ShopifyApp.__addMessageHandler "Shopify.API.initialize", (message, data) =>
      ShopifyApp.pushState @getWindowLocation().pathname + @getWindowLocation().search

    ShopifyApp.__addMessageHandler "Shopify.API.print", (message, data) ->
      window.focus()
      ShopifyApp.print()

    # Add the listener for messages
    if window.addEventListener
      window.addEventListener "message", ShopifyApp.__addEventMessageCallback, false
    else
      window.attachEvent "onMessage", ShopifyApp.__addEventMessageCallback

  @checkFrame: =>
    if window is @getWindowParent()
      redirectUrl = "#{ ShopifyApp.shopOrigin || "https://myshopify.com" }/admin/apps/"
      redirectUrl = redirectUrl + ShopifyApp.apiKey + @getWindowLocation().pathname + (@getWindowLocation().search or "") if ShopifyApp.apiKey

      if @forceRedirect
        ShopifyApp.log "ShopifyApp detected that it was not loaded in an iframe and is redirecting to: #{ redirectUrl }", true
        @setWindowLocation(redirectUrl)
      else
        ShopifyApp.log "ShopifyApp detected that it was not loaded in an iframe but redirecting is disabled! Redirect URL would be: #{ redirectUrl }", true

  @loadConfig: (config) ->
    @apiKey = config.apiKey
    @shopOrigin = config.shopOrigin
    @forceRedirect = if config.hasOwnProperty('forceRedirect') then !!config.forceRedirect else @forceRedirect = true
    @debug = !!config.debug

    @log "ShopifyApp warning: apiKey has not been set." unless @apiKey
    @log "ShopifyApp warning: shopOrigin has not been set." unless @shopOrigin
    @log "ShopifyApp warning: shopOrigin should include the protocol" if @shopOrigin && !@shopOrigin.match(/^http(s)?:\/\//)

  @log: (message, force) ->
    console.log message if console?.log and (@debug or force)

  @messageSlug: (prefix) ->
    characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    prefix = (prefix || "message") + "_"
    prefix += characters.charAt(Math.floor(Math.random() * characters.length)) for [0...16]
    prefix

  @print: ->
    window.print()

  @window: ->
    @getWindowParent().frames["app-iframe"]

  @postMessage: (message, data) ->
    json = JSON.stringify(
      message: message
      data: data
    )
    ShopifyApp.log "ShopifyApp client sent #{ json } to #{ @shopOrigin }"
    @getWindowParent().postMessage json, @shopOrigin

  @pushState: (location) ->
    ShopifyApp.postMessage "Shopify.API.pushState",
      location: location

  @flashError: (err) ->
    ShopifyApp.postMessage "Shopify.API.flash.error",
      message: err

  @flashNotice: (notice) ->
    ShopifyApp.postMessage "Shopify.API.flash.notice",
      message: notice

  @redirect: (location) ->
    ShopifyApp.postMessage "Shopify.API.redirect",
      location: location

  @Bar:
    initialize: (init) ->
      init = ShopifyApp.__addDefaultButtonMessages(init)
      ShopifyApp.__addButtonMessageHandlers init
      ShopifyApp.postMessage "Shopify.API.Bar.initialize", init

    loadingOn: ->
      ShopifyApp.postMessage "Shopify.API.Bar.loading.on"

    loadingOff: ->
      ShopifyApp.postMessage "Shopify.API.Bar.loading.off"

    setIcon: (icon) ->
      ShopifyApp.postMessage "Shopify.API.Bar.icon",
        icon: icon

    setTitle: (title) ->
      ShopifyApp.postMessage "Shopify.API.Bar.title",
        title: title

    setPagination: (pagination) ->
      init = ShopifyApp.__addDefaultButtonMessages({pagination: pagination})
      ShopifyApp.__addButtonMessageHandlers init
      ShopifyApp.postMessage "Shopify.API.Bar.pagination", init

  @Modal:
    __callback: undefined
    __open: (message, data, callback) ->
      ShopifyApp.Modal.__callback = callback
      ShopifyApp.postMessage message, data

    window: ->
      @getWindowParent().frames["app-modal-iframe"]

    open: (init, callback) ->
      init = ShopifyApp.__addDefaultButtonMessages(init)
      ShopifyApp.__addButtonMessageHandlers init, true
      ShopifyApp.Modal.__open "Shopify.API.Modal.open", init, callback

    alert: (message, callback) ->
      ShopifyApp.Modal.__open "Shopify.API.Modal.alert",
        message: message
      , callback

    confirm: (message, callback) ->
      ShopifyApp.Modal.__open "Shopify.API.Modal.confirm",
        message: message
      , callback

    input: (message, callback) ->
      ShopifyApp.Modal.__open "Shopify.API.Modal.input",
        message: message
      , callback

    close: (result, data) ->
      ShopifyApp.postMessage "Shopify.API.Modal.close",
        result: result
        data: data

  @__messageHandlers: {}
  @__modalMessages: []

  @__addDefaultButtonMessages: (init) ->
    if init.primaryButton?
      init.primaryButton.message = ShopifyApp.messageSlug("primaryButton") unless init.primaryButton.message

    if init.buttons?
      for button, i in init.buttons
        button.message = ShopifyApp.messageSlug("button#{ i }") unless button.message

    if init.pagination?.previous?
      init.pagination.previous.message = ShopifyApp.messageSlug("pagination_previous") unless init.pagination.previous.message
      init.pagination.previous.target = 'app' if init.pagination.previous.href

    if init.pagination?.next?
      init.pagination.next.message = ShopifyApp.messageSlug("pagination_next") unless init.pagination.next.message
      init.pagination.next.target = 'app' if init.pagination.next.href

    init

  @__addButtonMessageHandlers: (init, isModal) ->
    ShopifyApp.__addButtonMessageHandler(init.primaryButton, isModal) if init.primaryButton?
    ShopifyApp.__addButtonMessageHandler(button, isModal) for button in init.buttons if init.buttons?
    ShopifyApp.__addButtonMessageHandler(init.pagination.previous, isModal) if init.pagination?.previous?
    ShopifyApp.__addButtonMessageHandler(init.pagination.next, isModal) if init.pagination?.next?

  @__addButtonMessageHandler: (button, isModal) ->
    if button.action
      @log "DEPRECATION: Button 'action' is being removed and has been replaced with 'callback'.", true
      button.callback = button.action unless button.callback

    if button.target == 'app'
      button.callback = (message, data) =>
        @setWindowLocation(button.href)

    ShopifyApp.__addMessageHandler(button.message, button.callback, isModal) if typeof button.callback is "function"

  @__addMessageHandler: (message, fn, isModal) ->
    # allow us to accept function as the first param and fire that handler for all messages, keyed as undefined.
    if typeof message is "function"
      fn = message
      message = undefined
    ShopifyApp.__messageHandlers[message] = [] unless ShopifyApp.__messageHandlers[message]
    ShopifyApp.__modalMessages.push message if isModal
    ShopifyApp.__messageHandlers[message].push fn

  @__clearModalListeners: ->
    ShopifyApp.__modalMessages.forEach (message) ->
      delete ShopifyApp.__messageHandlers[message]
    ShopifyApp.__modalMessages = []

  @__addEventMessageCallback: (e) ->
    if e.origin is ShopifyApp.shopOrigin
      ShopifyApp.log "ShopifyApp client received #{ e.data } from #{ e.origin }"
      message = JSON.parse(e.data)

      # Launch the modal callback if it is present
      if message.message is "Shopify.API.Modal.close" and ShopifyApp.Modal.__callback
        ShopifyApp.__clearModalListeners()
        ShopifyApp.Modal.__callback message.data.result, message.data.data

      # Find all matching handlers
      handlers = []
      handlers = handlers.concat(ShopifyApp.__messageHandlers[message.message]) if ShopifyApp.__messageHandlers[message.message]
      handlers = handlers.concat(ShopifyApp.__messageHandlers[undefined]) if ShopifyApp.__messageHandlers[undefined]

      # Call each handler
      for handler in handlers
        handler message.message, message.data

      # Submit all forms that have the 'data-shopify-app-submit' attribute matching the message
      if submitForm = document.querySelector("form[data-shopify-app-submit=\"#{ message.message }\"]")
        submitForm.submit()
        return
    else
      ShopifyApp.log "ShopifyApp client received #{ e.data } from unknown origin #{ e.origin }. Expected #{ ShopifyApp.shopOrigin }."
