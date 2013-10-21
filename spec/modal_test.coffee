describe "ShopifyApp.Modal", ->
  Given -> @app = ShopifyApp
  Given -> spyOn(@app, 'postMessage')
  Given ->
    @message = "hi"
    @config =
      src: "http://example.com"
      primaryButton:
        label: "Ok"

  describe "#window", ->
    Given -> spyOn(@app, 'getWindowParent').andReturn({frames: {"app-modal-iframe": "ralph"}})
    Then  -> @app.Modal.window() == "ralph"

  describe "#open", ->
    When -> @app.Modal.open(@message)
    Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Modal.open", @message)

  describe "#alert", ->
    When -> @app.Modal.alert(@message)
    Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Modal.alert", {message: @message})

  describe "#confirm", ->
    When -> @app.Modal.confirm(@message)
    Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Modal.confirm", {message: @message})

  describe "#input", ->
    When -> @app.Modal.input(@message)
    Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Modal.input", {message: @message})

  describe "#confirm", ->
    When -> @app.Modal.close("closed", "data")
    Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Modal.close", {result: "closed", data: "data"})
