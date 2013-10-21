# embedded-app-js

[![Build Status](https://travis-ci.org/davemo/embedded-app-js.png?branch=master)](https://travis-ci.org/davemo/embedded-app-js)

# building embedded-app-js

If you're interested in working on embedded-app-js, it'll be important for you to be able to run the tests and build a distribution. Luckily this is really easy thanks to lineman-lib!

* clone this repo
* `npm install -g lineman`
* `npm install`
* `lineman run` in 1 terminal session (leave it running while you test)
* `lineman spec` in another terminal session

When you are ready to issue a build of the library, simply run `lineman build`. The output bundles will live in `dist/`, 1 minified, 1 unminified.

Don't forget to tag and push a release to github too :)
