describe "ShopifyApp", ->
  Given ->
    @app = ShopifyApp
    @app.debug = false
    @setWindowLocationSpy = spyOn(@app, 'setWindowLocation')
    @getWindowLocationSpy = spyOn(@app, 'getWindowLocation')
    @app.Modal.__callback = undefined
    @app.__messageHandlers = {}
    @app.shopOrigin = "https://piemart.myshopify.com"
    @callback = jasmine.createSpy()
    @defaultConfig =
      apiKey: 'apikey'
      shopOrigin: 'https://piemart.myshopify.com'

  describe "#ready", ->
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

#   @test 'ShopifyApp.messageSlug generates a random slug', ->
#     @assertMatch /^message_[A-Za-z0-9]{16}$/, ShopifyApp.messageSlug()
#     @assertMatch /^pie_[A-Za-z0-9]{16}$/, ShopifyApp.messageSlug("pie")

#   @test 'ShopifyApp.print should call focus and then print', ->
#     @mock(window).expects("print")
#     @mock(window).expects("focus").never()
#     ShopifyApp.print()

#   @test 'ShopifyApp.print handler should add the focus method outside of the print function', ->
#     ShopifyApp.init(@defaultConfig)
#     @mock(window).expects("focus")
#     @mock(window).expects("print")
#     @assertEqual 1, ShopifyApp.__messageHandlers["Shopify.API.print"].length
#     ShopifyApp.__messageHandlers["Shopify.API.print"][0]()

#   ## Bar

#   @test 'ShopifyApp.Bar.initialize posts an init message with modified button messages', ->
#     init =
#       primaryButton:
#         label: "Save"
#         callback: ->
#       buttons: [
#         label: "Cancel"
#         callback: ->
#       ]
#       title: 'Page Title'
#       icon: '/icon.png'

#     @mock(ShopifyApp).expects("__addDefaultButtonMessages").withArgs(init).returns(init)
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Bar.initialize", init)
#     @mock(ShopifyApp).expects("__addButtonMessageHandlers").withArgs(init)
#     ShopifyApp.Bar.initialize(init)

#   @test 'ShopifyApp.Bar.loadingOn calls postMessage', ->
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Bar.loading.on")
#     ShopifyApp.Bar.loadingOn()

#   @test 'ShopifyApp.Bar.loadingOff calls postMessage', ->
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Bar.loading.off")
#     ShopifyApp.Bar.loadingOff()

#   @test 'ShopifyApp.Bar.setIcon calls postMessage', ->
#     icon = "/icon.png"
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Bar.icon", {icon})
#     ShopifyApp.Bar.setIcon(icon)

#   @test 'ShopifyApp.Bar.setTitle calls postMessage', ->
#     title = "The Title"
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Bar.title", {title})
#     ShopifyApp.Bar.setTitle(title)

#   @test 'ShopifyApp.Bar.setPagination calls postMessage', ->
#     init = {pagination: {the: "config"}}
#     @mock(ShopifyApp).expects("__addDefaultButtonMessages").returns(init)
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Bar.pagination", init)
#     @mock(ShopifyApp).expects("__addButtonMessageHandlers").withArgs(init)
#     ShopifyApp.Bar.setPagination(init)

#   ## Modal

#   @test 'ShopifyApp.Modal.open should post message and set the callback', ->
#     init =
#       src: "http://example.com"
#       primaryButton:
#         label: "Ok"

#     @mock(ShopifyApp).expects("__addDefaultButtonMessages").withArgs(init).returns(init)
#     @mock(ShopifyApp).expects("__addButtonMessageHandlers").withArgs(init)
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Modal.open", init)
#     ShopifyApp.Modal.open(init, @callback)
#     @assertEqual @callback, ShopifyApp.Modal.__callback

#   @test 'ShopifyApp.Modal.alert should post message and set the callback', ->
#     message = "Pie is delicious"
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Modal.alert", {message})
#     ShopifyApp.Modal.alert(message, @callback)
#     @assertEqual @callback, ShopifyApp.Modal.__callback

#   @test 'ShopifyApp.Modal.confirm should post message and set the callback', ->
#     message = "Pie is delicious"
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Modal.confirm", {message})
#     ShopifyApp.Modal.confirm(message, @callback)
#     @assertEqual @callback, ShopifyApp.Modal.__callback

#   @test 'ShopifyApp.Modal.input should post message and set the callback', ->
#     message = "Pie is delicious"
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Modal.input", {message})
#     ShopifyApp.Modal.input(message, @callback)
#     @assertEqual @callback, ShopifyApp.Modal.__callback

#   @test 'ShopifyApp.Modal.close should post message', ->
#     result = "result"
#     data = "data"
#     @mock(ShopifyApp).expects("postMessage").withArgs("Shopify.API.Modal.close", {result, data})
#     ShopifyApp.Modal.close(result, data)

#   ## Private

#   @test 'ShopifyApp.__addMessageHandler should add a handler for a message', ->
#     message = "pie_is_delicious"
#     fn = ->
#     ShopifyApp.__addMessageHandler(message, fn)
#     @assertEqual [fn], ShopifyApp.__messageHandlers[message]

#   @test 'ShopifyApp.__addMessageHandler should add a handler for all messages', ->
#     fn = ->
#     ShopifyApp.__addMessageHandler(fn)
#     @assertEqual [fn], ShopifyApp.__messageHandlers[undefined]

#   @test 'ShopifyApp.__addEventMessageCallback should not fire if the origins do not match', ->
#     @mock(document).expects('querySelector').never()
#     ShopifyApp.__addEventMessageCallback({origin: "fake.com"})

#   @test 'ShopifyApp.__addEventMessageCallback should fire the modal callback and clear modal listeners', ->
#     @mock(ShopifyApp).expects("__clearModalListeners")
#     ShopifyApp.Modal.__callback = (result, data) =>
#       @assert result
#       @assertEqual "pie", data
#     ShopifyApp.__addEventMessageCallback
#       origin: "https://piemart.myshopify.com"
#       data: JSON.stringify
#         message: "Shopify.API.Modal.close"
#         data:
#           data: "pie"
#           result: true

#   @test 'ShopifyApp.__addEventMessageCallback should fire the callback for the handlers for the message and for the "all" case', 4, ->
#     ShopifyApp.__messageHandlers =
#       "Shopify.API.redirect": (message, data) =>
#         @assertEqual 'Shopify.API.redirect', message
#         @assertEqual "/products", data.data
#       undefined: (message, data) =>
#         @assertEqual 'Shopify.API.redirect', message
#         @assertEqual "/products", data.data
#       "this.message.is.never.called": (message, data) =>
#         @assert false # This callback shouldn't be called, so if it does fail the test.

#     ShopifyApp.__addEventMessageCallback
#       origin: "https://piemart.myshopify.com"
#       data: JSON.stringify
#         message: "Shopify.API.redirect"
#         data:
#           data: "/products"

#   @test 'ShopifyApp.__addEventMessageCallback should fire the form data tags', ->
#     form =
#       submit: ->
#     @mock(form).expects("submit")
#     @mock(document).expects("querySelector").withArgs("form[data-shopify-app-submit=\"Shopify.API.redirect\"]").returns(form)

#     ShopifyApp.__addEventMessageCallback
#       origin: "https://piemart.myshopify.com"
#       data: JSON.stringify
#         message: "Shopify.API.redirect"

#   @test 'ShopifyApp.__addButtonMessageHandlers should delegate to __addButtonMessageHandler', ->
#     primaryButton = {message: "primaryButton"}
#     button0 = {message: "button0"}
#     button1 = {message: "button1"}
#     pagination_previous = {message: "previous"}
#     pagination_next = {message: "next"}
#     obj = @mock(ShopifyApp)

#     obj.expects('__addButtonMessageHandler').withArgs(primaryButton)
#     obj.expects('__addButtonMessageHandler').withArgs(button0)
#     obj.expects('__addButtonMessageHandler').withArgs(button1)
#     obj.expects('__addButtonMessageHandler').withArgs(pagination_next)
#     obj.expects('__addButtonMessageHandler').withArgs(pagination_previous)

#     ShopifyApp.__addButtonMessageHandlers
#       primaryButton: primaryButton
#       buttons: [button0, button1]
#       pagination:
#         next: pagination_next
#         previous: pagination_previous

#   @test 'ShopifyApp.__addButtonMessageHandler should add the handler', ->
#     button =
#       message: "button_message"
#       callback: ->

#     @mock(ShopifyApp).expects('__addMessageHandler').withArgs(button.message, button.callback, true)
#     ShopifyApp.__addButtonMessageHandler(button, true)

#   @test 'ShopifyApp.__addButtonMessageHandler should not fire if the callback is not a function', ->
#     @mock(ShopifyApp).expects('__addMessageHandler').never()
#     ShopifyApp.__addButtonMessageHandler({})

#   @test 'ShopifyApp.__addButtonMessageHandler add the callback for "app" target links', ->
#     button =
#       message: "button_message"
#       target: 'app'
#     callback = (message, data) =>
#       window.location = button.href

#     ShopifyApp.__addButtonMessageHandler(button, false)
#     @assertEqual 'function', typeof ShopifyApp.__messageHandlers["button_message"][0]

#   @test 'ShopifyApp.__addDefaultButtonMessages should not do anything if there are no options passed', ->
#     result = ShopifyApp.__addDefaultButtonMessages({})
#     @assertEqual result, {}

#   @test 'ShopifyApp.__addDefaultButtonMessages adds the missing messages', ->
#     result = ShopifyApp.__addDefaultButtonMessages
#       primaryButton: {}
#       buttons: [{}]
#       pagination:
#         previous: {}
#         next: {}

#     @assert result.primaryButton.message
#     @assert result.buttons[0].message
#     @assert result.pagination.next.message
#     @assert result.pagination.previous.message
#     @assert !result.pagination.next.target
#     @assert !result.pagination.previous.target

#   @test 'ShopifyApp.__addDefaultButtonMessages should not modify existing messages', ->
#     result = ShopifyApp.__addDefaultButtonMessages
#       primaryButton:
#         message: 'primaryButton_message'
#       buttons: [{message: 'button_message'}]
#       pagination:
#         previous:
#           message: 'previous_message'
#         next:
#           message: 'next_message'

#     @assertEqual 'primaryButton_message', result.primaryButton.message
#     @assertEqual 'button_message', result.buttons[0].message
#     @assertEqual 'next_message', result.pagination.next.message
#     @assertEqual 'previous_message', result.pagination.previous.message

#   @test 'ShopifyApp.__addDefaultButtonMessages should add target: "app" for pagination with href', ->
#     result = ShopifyApp.__addDefaultButtonMessages
#       pagination:
#         previous:
#           href: 'value'
#         next:
#           callback: ->
#     @assert !result.pagination.next.target
#     @assertEqual 'app', result.pagination.previous.target

# test = new Shopify.ExternalShopifyAppTest
# test.runTests()
