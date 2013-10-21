describe "ShopifyApp.Bar", ->
  Given -> @app = ShopifyApp

  describe "Bar", ->
    Given -> spyOn(@app, 'postMessage')
    Given -> @config =
      primaryButton:
        label: "Save"
        callback: ->
      buttons: [
        label: "Cancel"
        callback: ->
      ]
      title: 'Page Title'
      icon: '/icon.png'

    describe "#initialize", ->
      When  -> @app.Bar.initialize(@config)
      Then  -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Bar.initialize", @config)

    describe "apis that call ShopifyApp.postMessage", ->

      describe "#loadingOn", ->
        When -> @app.Bar.loadingOn()
        Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Bar.loading.on")

      describe "#loadingOff", ->
        When -> @app.Bar.loadingOff()
        Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Bar.loading.off")

      describe "#setIcon", ->
        When -> @app.Bar.setIcon("ralph")
        Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Bar.icon", {icon: "ralph"})

      describe "#setTitle", ->
        When -> @app.Bar.setTitle("ralph")
        Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Bar.title", {title: "ralph"})

      describe "#setPagination", ->
        Given -> @config = {the: "config"}
        When -> @app.Bar.setPagination(@config)
        Then -> expect(@app.postMessage).toHaveBeenCalledWith("Shopify.API.Bar.pagination", {pagination: @config})
