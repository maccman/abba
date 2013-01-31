# Abba

Abba is a simple a/b testing self-hosted framework, built to help improve your site's conversion.

* Simple JavaScript API
* Multi variant support
* Filter results by date and browser

![Screenshot](http://stripe.github.com/abba/screenshot.png)

## A/B testing API

First include abba.js using a script tag. The host of this url will need to point to wherever you deployed the app.

    <script src="//localhost:4050/v1/abba.js"></script>

Then call `Abba()`, passing in a test name and set up the control test and variants.

    <script>
      Abba('test name')
        .control(function(){ /* ... */ })
        .variant('test b', function(){ /* ... */ })
        .start();
    </script>

The *control* is whatever you're testing against, and is usually the original page. You should only have one control (and the callback can be omitted).

The *variants* are the variations on the control that you hope will improve conversion. You can specify multiple variants. They require a variant name, and a callback function.

When you call `start()` Abba will randomly execute the control or variants' callbacks, and record the results server side.

Once the user has successfully completed the experiment, say paid and navigated to a receipt page, you need to complete the test. You can do this by invoking `complete()`.

    <script>
      // On successful conversion
      Abba('test name').complete();
    </script>

You can find a more complete example under `./public/test`.

## Setup

Requirements:

* Ruby 1.9.3
* Mongo

The default username and password are `guard` / `llama`. Change these in `config.yml`, unless you want everybody to access your test results. SSL is required in an production environment by default.

To run locally:

    bundle install
    thin start

## Heroku 10 seconds setup

    heroku create myapp
    heroku addons:add mongohq:sandbox
    git push heroku master
    heroku open
