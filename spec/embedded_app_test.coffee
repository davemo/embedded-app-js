describe "ShopifyApp", ->
  Given ->
    spyOn(window, 'print')
    spyOn(window, 'focus')
    @app = ShopifyApp
    @app.debug = false
    @setWindowLocationSpy = spyOn(@app, 'setWindowLocation')
    @getWindowLocationSpy = spyOn(@app, 'getWindowLocation')
    @app.Modal.__callback = undefined
    @app.__messageHandlers = {}
    @app.shopOrigin = "https://piemart.myshopify.com"
    @defaultConfig =
      apiKey: 'apikey'
      shopOrigin: 'https://piemart.myshopify.com'

  describe "#ready", ->
    Given -> @callback = jasmine.createSpy()
    Given -> spyOn(@app, '__addMessageHandler')
    When  -> @app.ready(@callback)
    Then  -> expect(@app.__addMessageHandler).toHaveBeenCalledWith("Shopify.API.initialize", @callback)

  describe "#init", ->
    Given ->
      @windowLocation = {pathname: "/context.html", search: "?ralph=wiggum"}
      @setWindowLocationSpy.andReturn(@windowLocation)
      @getWindowLocationSpy.andReturn(@windowLocation)
      spyOn(@app, 'pushState')
      spyOn(window, 'addEventListener')

    When -> @app.init(@defaultConfig)

    describe "adding a message handler", ->
      Then -> @app.__messageHandlers["Shopify.API.initialize"].length == 1

    describe "adding a print message handler", ->
      Given -> spyOn(@app, 'print')
      When -> @app.__messageHandlers["Shopify.API.print"][0]()
      Then -> @app.__messageHandlers["Shopify.API.print"].length == 1
      Then -> expect(@app.print).toHaveBeenCalled()
      Then -> expect(window.focus).toHaveBeenCalled()

    describe "invoking pushState", ->
      When -> @app.__messageHandlers["Shopify.API.initialize"][0]()
      Then -> expect(@app.pushState).toHaveBeenCalledWith("/context.html?ralph=wiggum")

    describe "adding window listener for modern browsers", ->
      Then -> expect(window.addEventListener).toHaveBeenCalledWith("message", @app.__addEventMessageCallback, false)

    describe "adding a window listener for IE", ->
      Given -> window.addEventListener = undefined
      Given -> window.attachEvent = jasmine.createSpy()
      When  -> @app.init(@defaultConfig)
      Then  -> expect(window.attachEvent).toHaveBeenCalledWith("onMessage", @app.__addEventMessageCallback)

  describe "#loadConfig", ->
    describe "initializes the values", ->
      Given -> @config = {apiKey: "thekey", shopOrigin: "https://theshop.myshopify.com", debug: "yes", forceRedirect: null}
      When  -> @app.loadConfig(@config)
      Then  -> @app.apiKey == "thekey"
      Then  -> @app.shopOrigin == "https://theshop.myshopify.com"
      Then  -> @app.forceRedirect == false
      Then  -> @app.debug == true

    describe "has sane defaults", ->
      When -> @app.loadConfig({})
      Then -> @app.apiKey == undefined
      Then -> @app.shopOrigin == undefined
      Then -> @app.forceRedirect == true
      Then -> @app.debug == false

  describe "#postMessage", ->
    Given -> @parent = {postMessage: jasmine.createSpy()}
    Given -> spyOn(@app, 'getWindowParent').andReturn(@parent)
    When  -> @app.postMessage("pie", "is delicious")
    Then  -> expect(@parent.postMessage).toHaveBeenCalledWith(JSON.stringify({message: "pie", data: "is delicious"}), "https://piemart.myshopify.com")

    describe "apis that call ShopifyApp.postMessage", ->
      Given -> spyOn(@app, 'postMessage')

      describe "#pushState", ->
        Given -> @location = "http://pie.com"
        When  -> @app.pushState(@location)
        Then  -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.pushState", {location: @location})

      describe "#flashError", ->
        Given -> @message = "delicious"
        When  -> @app.flashError(@message)
        Then  -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.flash.error", {message: @message})

      describe "#flashNotice", ->
        Given -> @message = "delicious"
        When  -> @app.flashNotice(@message)
        Then  -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.flash.notice", {message: @message})

      describe "#redirect", ->
        Given -> @location = "some.place"
        When  -> @app.redirect(@location)
        Then  -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.redirect", {location: @location})

  describe "#messageSlug", ->

    context "default", ->
      When -> @message = @app.messageSlug()
      Then -> _.str.startsWith(@message, "message")

    context "with argument", ->
      When -> @message = @app.messageSlug("pie")
      Then -> _.str.startsWith(@message, "pie")

  describe "#print", ->
    When  -> @app.print()
    Then  -> expect(window.print).toHaveBeenCalled()
