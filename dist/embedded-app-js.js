/* embedded-app-js - 0.0.1
 * External JS file for use in Shopify embedded apps. Provides a JS API to postMessages to and from the Shopify admin.
 * https://github.com/shopify/embedded-app-js
 */
(function() {
  window.ShopifyApp = (function() {
    var _this = this;

    function ShopifyApp() {}

    ShopifyApp.debug = false;

    ShopifyApp.forceRedirect = true;

    ShopifyApp.apiKey = "";

    ShopifyApp.shopOrigin = "";

    ShopifyApp.setWindowLocation = function(location) {
      return window.location = location;
    };

    ShopifyApp.getWindowLocation = function() {
      return window.location;
    };

    ShopifyApp.getWindowParent = function() {
      return window.parent;
    };

    ShopifyApp.ready = function(fn) {
      return ShopifyApp.__addMessageHandler("Shopify.API.initialize", fn);
    };

    ShopifyApp.init = function(config) {
      var _this = this;
      if (config == null) {
        config = {};
      }
      this.loadConfig(config);
      this.checkFrame();
      ShopifyApp.__addMessageHandler("Shopify.API.initialize", function(message, data) {
        return ShopifyApp.pushState(_this.getWindowLocation().pathname + _this.getWindowLocation().search);
      });
      ShopifyApp.__addMessageHandler("Shopify.API.print", function(message, data) {
        window.focus();
        return ShopifyApp.print();
      });
      if (window.addEventListener) {
        return window.addEventListener("message", ShopifyApp.__addEventMessageCallback, false);
      } else {
        return window.attachEvent("onMessage", ShopifyApp.__addEventMessageCallback);
      }
    };

    ShopifyApp.checkFrame = function() {
      var redirectUrl;
      if (window === ShopifyApp.getWindowParent()) {
        redirectUrl = "" + (ShopifyApp.shopOrigin || "https://myshopify.com") + "/admin/apps/";
        if (ShopifyApp.apiKey) {
          redirectUrl = redirectUrl + ShopifyApp.apiKey + ShopifyApp.getWindowLocation().pathname + (ShopifyApp.getWindowLocation().search || "");
        }
        if (ShopifyApp.forceRedirect) {
          ShopifyApp.log("ShopifyApp detected that it was not loaded in an iframe and is redirecting to: " + redirectUrl, true);
          return ShopifyApp.setWindowLocation(redirectUrl);
        } else {
          return ShopifyApp.log("ShopifyApp detected that it was not loaded in an iframe but redirecting is disabled! Redirect URL would be: " + redirectUrl, true);
        }
      }
    };

    ShopifyApp.loadConfig = function(config) {
      this.apiKey = config.apiKey;
      this.shopOrigin = config.shopOrigin;
      this.forceRedirect = config.hasOwnProperty('forceRedirect') ? !!config.forceRedirect : this.forceRedirect = true;
      this.debug = !!config.debug;
      if (!this.apiKey) {
        this.log("ShopifyApp warning: apiKey has not been set.");
      }
      if (!this.shopOrigin) {
        this.log("ShopifyApp warning: shopOrigin has not been set.");
      }
      if (this.shopOrigin && !this.shopOrigin.match(/^http(s)?:\/\//)) {
        return this.log("ShopifyApp warning: shopOrigin should include the protocol");
      }
    };

    ShopifyApp.log = function(message, force) {
      if ((typeof console !== "undefined" && console !== null ? console.log : void 0) && (this.debug || force)) {
        return console.log(message);
      }
    };

    ShopifyApp.messageSlug = function(prefix) {
      var characters, _i;
      characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
      prefix = (prefix || "message") + "_";
      for (_i = 0; _i < 16; _i++) {
        prefix += characters.charAt(Math.floor(Math.random() * characters.length));
      }
      return prefix;
    };

    ShopifyApp.print = function() {
      return window.print();
    };

    ShopifyApp.window = function() {
      return this.getWindowParent().frames["app-iframe"];
    };

    ShopifyApp.postMessage = function(message, data) {
      var json;
      json = JSON.stringify({
        message: message,
        data: data
      });
      ShopifyApp.log("ShopifyApp client sent " + json + " to " + this.shopOrigin);
      return this.getWindowParent().postMessage(json, this.shopOrigin);
    };

    ShopifyApp.pushState = function(location) {
      return ShopifyApp.postMessage("Shopify.API.pushState", {
        location: location
      });
    };

    ShopifyApp.flashError = function(err) {
      return ShopifyApp.postMessage("Shopify.API.flash.error", {
        message: err
      });
    };

    ShopifyApp.flashNotice = function(notice) {
      return ShopifyApp.postMessage("Shopify.API.flash.notice", {
        message: notice
      });
    };

    ShopifyApp.redirect = function(location) {
      return ShopifyApp.postMessage("Shopify.API.redirect", {
        location: location
      });
    };

    ShopifyApp.Bar = {
      initialize: function(init) {
        init = ShopifyApp.__addDefaultButtonMessages(init);
        ShopifyApp.__addButtonMessageHandlers(init);
        return ShopifyApp.postMessage("Shopify.API.Bar.initialize", init);
      },
      loadingOn: function() {
        return ShopifyApp.postMessage("Shopify.API.Bar.loading.on");
      },
      loadingOff: function() {
        return ShopifyApp.postMessage("Shopify.API.Bar.loading.off");
      },
      setIcon: function(icon) {
        return ShopifyApp.postMessage("Shopify.API.Bar.icon", {
          icon: icon
        });
      },
      setTitle: function(title) {
        return ShopifyApp.postMessage("Shopify.API.Bar.title", {
          title: title
        });
      },
      setPagination: function(pagination) {
        var init;
        init = ShopifyApp.__addDefaultButtonMessages({
          pagination: pagination
        });
        ShopifyApp.__addButtonMessageHandlers(init);
        return ShopifyApp.postMessage("Shopify.API.Bar.pagination", init);
      }
    };

    ShopifyApp.Modal = {
      __callback: void 0,
      __open: function(message, data, callback) {
        ShopifyApp.Modal.__callback = callback;
        return ShopifyApp.postMessage(message, data);
      },
      window: function() {
        return ShopifyApp.getWindowParent().frames["app-modal-iframe"];
      },
      open: function(init, callback) {
        init = ShopifyApp.__addDefaultButtonMessages(init);
        ShopifyApp.__addButtonMessageHandlers(init, true);
        return ShopifyApp.Modal.__open("Shopify.API.Modal.open", init, callback);
      },
      alert: function(message, callback) {
        return ShopifyApp.Modal.__open("Shopify.API.Modal.alert", {
          message: message
        }, callback);
      },
      confirm: function(message, callback) {
        return ShopifyApp.Modal.__open("Shopify.API.Modal.confirm", {
          message: message
        }, callback);
      },
      input: function(message, callback) {
        return ShopifyApp.Modal.__open("Shopify.API.Modal.input", {
          message: message
        }, callback);
      },
      close: function(result, data) {
        return ShopifyApp.postMessage("Shopify.API.Modal.close", {
          result: result,
          data: data
        });
      }
    };

    ShopifyApp.__messageHandlers = {};

    ShopifyApp.__modalMessages = [];

    ShopifyApp.__addDefaultButtonMessages = function(init) {
      var button, i, _i, _len, _ref, _ref1, _ref2;
      if (init.primaryButton != null) {
        if (!init.primaryButton.message) {
          init.primaryButton.message = ShopifyApp.messageSlug("primaryButton");
        }
      }
      if (init.buttons != null) {
        _ref = init.buttons;
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          button = _ref[i];
          if (!button.message) {
            button.message = ShopifyApp.messageSlug("button" + i);
          }
        }
      }
      if (((_ref1 = init.pagination) != null ? _ref1.previous : void 0) != null) {
        if (!init.pagination.previous.message) {
          init.pagination.previous.message = ShopifyApp.messageSlug("pagination_previous");
        }
        if (init.pagination.previous.href) {
          init.pagination.previous.target = 'app';
        }
      }
      if (((_ref2 = init.pagination) != null ? _ref2.next : void 0) != null) {
        if (!init.pagination.next.message) {
          init.pagination.next.message = ShopifyApp.messageSlug("pagination_next");
        }
        if (init.pagination.next.href) {
          init.pagination.next.target = 'app';
        }
      }
      return init;
    };

    ShopifyApp.__addButtonMessageHandlers = function(init, isModal) {
      var button, _i, _len, _ref, _ref1, _ref2;
      if (init.primaryButton != null) {
        ShopifyApp.__addButtonMessageHandler(init.primaryButton, isModal);
      }
      if (init.buttons != null) {
        _ref = init.buttons;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          button = _ref[_i];
          ShopifyApp.__addButtonMessageHandler(button, isModal);
        }
      }
      if (((_ref1 = init.pagination) != null ? _ref1.previous : void 0) != null) {
        ShopifyApp.__addButtonMessageHandler(init.pagination.previous, isModal);
      }
      if (((_ref2 = init.pagination) != null ? _ref2.next : void 0) != null) {
        return ShopifyApp.__addButtonMessageHandler(init.pagination.next, isModal);
      }
    };

    ShopifyApp.__addButtonMessageHandler = function(button, isModal) {
      var _this = this;
      if (button.action) {
        this.log("DEPRECATION: Button 'action' is being removed and has been replaced with 'callback'.", true);
        if (!button.callback) {
          button.callback = button.action;
        }
      }
      if (button.target === 'app') {
        button.callback = function(message, data) {
          return _this.setWindowLocation(button.href);
        };
      }
      if (typeof button.callback === "function") {
        return ShopifyApp.__addMessageHandler(button.message, button.callback, isModal);
      }
    };

    ShopifyApp.__addMessageHandler = function(message, fn, isModal) {
      if (typeof message === "function") {
        fn = message;
        message = void 0;
      }
      if (!ShopifyApp.__messageHandlers[message]) {
        ShopifyApp.__messageHandlers[message] = [];
      }
      if (isModal) {
        ShopifyApp.__modalMessages.push(message);
      }
      return ShopifyApp.__messageHandlers[message].push(fn);
    };

    ShopifyApp.__clearModalListeners = function() {
      ShopifyApp.__modalMessages.forEach(function(message) {
        return delete ShopifyApp.__messageHandlers[message];
      });
      return ShopifyApp.__modalMessages = [];
    };

    ShopifyApp.__addEventMessageCallback = function(e) {
      var handler, handlers, message, submitForm, _i, _len;
      if (e.origin === ShopifyApp.shopOrigin) {
        ShopifyApp.log("ShopifyApp client received " + e.data + " from " + e.origin);
        message = JSON.parse(e.data);
        if (message.message === "Shopify.API.Modal.close" && ShopifyApp.Modal.__callback) {
          ShopifyApp.__clearModalListeners();
          ShopifyApp.Modal.__callback(message.data.result, message.data.data);
        }
        handlers = [];
        if (ShopifyApp.__messageHandlers[message.message]) {
          handlers = handlers.concat(ShopifyApp.__messageHandlers[message.message]);
        }
        if (ShopifyApp.__messageHandlers[void 0]) {
          handlers = handlers.concat(ShopifyApp.__messageHandlers[void 0]);
        }
        for (_i = 0, _len = handlers.length; _i < _len; _i++) {
          handler = handlers[_i];
          handler(message.message, message.data);
        }
        if (submitForm = document.querySelector("form[data-shopify-app-submit=\"" + message.message + "\"]")) {
          submitForm.submit();
        }
      } else {
        return ShopifyApp.log("ShopifyApp client received " + e.data + " from unknown origin " + e.origin + ". Expected " + ShopifyApp.shopOrigin + ".");
      }
    };

    return ShopifyApp;

  }).call(this);

}).call(this);
