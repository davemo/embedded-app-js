describe "ShopifyApp Private Methods", ->
  Given -> @app = ShopifyApp

  describe "#__addMessageHandler", ->

    Given -> @handler = jasmine.createSpy()

    context "handler for a single message", ->
      Given -> @message = "pie_is_delicious"
      When  -> @app.__addMessageHandler(@message, @handler)
      Then  -> _(@app.__messageHandlers[@message]).contains(@handler)

    context "handler for all messages", ->
      When -> @app.__addMessageHandler(@handler)
      Then -> _(@app.__messageHandlers[@message]).contains(@handler)

  describe "#__addEventMessageCallback", ->

    context "origins dont match", ->
      Given -> spyOn(document, 'querySelector')
      When -> @app.__addEventMessageCallback({origin: "notpiemart.myshopify.com"})
      Then -> expect(document.querySelector).not.toHaveBeenCalled()

    context "origins match", ->
      Given -> @callback = jasmine.createSpy()
      Given -> @app.Modal.__callback = @callback
      Given ->
        @config =
          origin: "https://piemart.myshopify.com"
          data: JSON.stringify({message: "Shopify.API.Modal.close", data: {data: "pie", result: true}})

      When  -> @app.__addEventMessageCallback(@config)

      Then  -> expect(@callback).toHaveBeenCalledWith(true, "pie")

    context "specific and general message handlers exist", ->
      Given -> @redirectHandler = jasmine.createSpy()
      Given -> @uncalledHandler = jasmine.createSpy()
      Given -> @app.__messageHandlers["Shopify.API.redirect"] = @redirectHandler
      Given -> @app.__messageHandlers["this.message.is.never.called"] = @redirectHandler
      Given -> @app.__messageHandlers["undefined"] = @uncalledHandler
      Given ->
        @config =
          origin: "https://piemart.myshopify.com"
          data: JSON.stringify({message: "Shopify.API.redirect", data: {data: "/products"}})

      When  -> @app.__addEventMessageCallback(@config)

      Then  -> expect(@redirectHandler).toHaveBeenCalledWith("Shopify.API.redirect", {data: "/products"})
      Then  -> expect(@uncalledHandler).not.toHaveBeenCalledWith()

    context "redirect message should submit the form", ->
      Given -> @submitSpy = jasmine.createSpy()
      Given -> spyOn(document, 'querySelector').andReturn(submit: @submitSpy)
      Given ->
        @config =
          origin: "https://piemart.myshopify.com"
          data: JSON.stringify({message: "Shopify.API.redirect"})

      When -> @app.__addEventMessageCallback(@config)

      Then -> expect(@submitSpy).toHaveBeenCalled()

  describe "#__addButtonMessageHandlers", ->

    Given -> @addSpy = spyOn(@app, '__addButtonMessageHandler')

    describe "delegating to __addButtonMessageHandler", ->
      Given ->
        @primaryButton = {message: "primaryButton"}
        @button0 = {message: "button0"}
        @button1 = {message: "button1"}
        @pagination_previous = {message: "previous"}
        @pagination_next = {message: "next"}

      When ->
        @app.__addButtonMessageHandlers
          primaryButton: @primaryButton
          buttons: [@button0, @button1]
          pagination:
            next: @pagination_next
            previous: @pagination_previous

      Then -> @addSpy.argsForCall[0][0] == @primaryButton
      Then -> @addSpy.argsForCall[1][0] == @button0
      Then -> @addSpy.argsForCall[2][0] == @button1
      Then -> @addSpy.argsForCall[3][0] == @pagination_previous
      Then -> @addSpy.argsForCall[4][0] == @pagination_next

  describe "#__addButtonMessageHandler", ->
    Given -> @callback = jasmine.createSpy()
    Given -> @button = {message: "button_message", callback: @callback}
    Given -> @app.__messageHandlers = {} #having to reset this kind of sucks, but as is the way of testing singletons :(

    context "callback is a function", ->
      When  -> @app.__addButtonMessageHandler(@button, true)
      Then  -> typeof @app.__messageHandlers[@button.message][0] == 'function'

    context "callback is undefined", ->
      Given -> @button.callback = undefined
      When  -> @app.__addButtonMessageHandler(@button, true)
      Then  -> typeof @app.__messageHandlers[@button.message] == 'undefined'

    context "target is app", ->
      Given -> @button.target = 'app'
      When  -> @app.__addButtonMessageHandler(@button, false)
      Then  -> typeof @app.__messageHandlers[@button.message][0] == 'function'

  describe "#__addDefaultButtonMessages", ->

    context "messages are missing", ->
      When ->
        @result = @app.__addDefaultButtonMessages
          primaryButton: {}
          buttons: [{}]
          pagination:
            previous: {}
            next: {}

      Then "default messages are assigned", ->
        expect(@result.primaryButton.message).toBeDefined()
        expect(@result.buttons[0].message).toBeDefined()
        expect(@result.pagination.next.message).toBeDefined()
        expect(@result.pagination.previous.message).toBeDefined()
        expect(@result.pagination.next.target).not.toBeDefined()
        expect(@result.pagination.previous.target).not.toBeDefined()

    context "messages exist", ->
      When ->
        @result = @app.__addDefaultButtonMessages
          primaryButton:
            message: 'primaryButton_message'
          buttons: [{message: 'button_message'}]
          pagination:
            previous:
              message: 'previous_message'
            next:
              message: 'next_message'

      Then -> @result.primaryButton.message == 'primaryButton_message'
      Then -> @result.buttons[0].message == 'button_message'
      Then -> @result.pagination.next.message == 'next_message'
      Then -> @result.pagination.previous.message == 'previous_message'

    context "pagination has href", ->
      When ->
        @result = @app.__addDefaultButtonMessages
          pagination:
            previous:
              href: 'value'
            next:
              callback: ->

      Then -> @result.pagination.previous.target == 'app'
      Then -> @result.pagination.next.target == undefined
