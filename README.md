# Abba

Abba is a simple a/b testing self-hosted framework built to help improve conversion rates on your site.

* Simple JavaScript API
* Multi variant support
* Filter results by date and browser

![Screenshot](http://stripe.github.com/abba/screenshot.png)

## Setup

Requirements:

* Ruby 1.9.3
* Mongo

The default username and password are `guard` / `llama`. Change these in `config.yml` or set the environment variables `ABBA_USERNAME` and `ABBA_PASSWORD`, unless you want everybody to access your test results.
The environment variables have precedence over the config file. SSL is required in an production environment by default.

To run locally:

    bundle install
    thin start

## Heroku 10 seconds setup

    git clone git://github.com/maccman/abba.git && cd abba
    heroku create
    heroku addons:add mongolab:sandbox
    git push heroku master
    heroku open

The default username and password are `guard` / `llama`.

## A/B testing API

First include abba.js using a script tag. The host of this url will need to point to wherever you deployed the app.

    <script src="//localhost:4050/v1/abba.js"></script>

Then call `Abba()`, passing in a test name and set up the control test and variants.

    <script>
      Abba('test name')
        .control('test a', function(){ /* ... */ })
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

## TLDR example

    <script src="//my-abba.herokuapp.com/v1/abba.js"></script>

    <script>
      Abba('Checkout')
        .control()
        .variant('Text: Complete Purchase', function(){
          $('form button').text('Complete Purchase');
        })
        .variant('Color: green', function(){
          $('form button').css({background: 'green'});
        })
        .start();
    </script>

You can find a more complete example under `./public/test`.

## Options

### Persisting results

If set the `persist` option to `true`, then the experiment won't be reset once it has completed. In other words, that visitor will always see that particular variant, and no more results will be recorded for that visitor.

    <script>
      Abba('Pricing', {persist: true}).complete();
    </script>

### Weighting

You can set a variant weight, so some variants are used more than others:

    Abba('My Checkout')
      .control('Control', {weight: 20})
      .variant('Variant 1', {weight: 3}, function(){
        $('#test').text('Variant 1 was chosen!');
      })
      .variant('Variant 2', {weight: 3}, function(){
        $('#test').text('Variant 2 was chosen!');
      })
      .start();

In the case above, the Control will be invoked 20 times more often than the other variants.

### Flow control

You can continue a previously started test using `continue()`.

    Abba('My Checkout')
      .control()
      .variant('Variant 1', function(){
        $('#test').text('Variant 1 was chosen!');
      })
      .variant('Variant 2', function(){
        $('#test').text('Variant 2 was chosen!');
      })
      .continue();

Nothing will be recorded if you call `continue()` instead of `start()`. If a variant hasn't been chosen previously, nothing will be executed.

You can reset tests using `reset()`.

    Abba('My Checkout').reset();

Lastly, you can calculate the test that you want to run server side, and just tell the JavaScript library which flow was chosen.

    Abba('My Checkout').start('Variant A')

### Links

If you're triggering the completion of a test on a link click or a form submit, then things get a bit more complicated.

You need to ensure that tracking request doesn't get lost (which can happen in some browsers if you request an image at the same time as
navigating). If the link is navigating to an external page which you don't control, then you have no choice but to cancel the link's default
event, wait a few milliseconds, then navigate manually:

    <script>
      $('body').on('click', 'a.external', function(e){
        // Prevent navigation
        e.preventDefault();
        var href = $(this).attr('href');

        Abba('My Links').complete();

        setTimeout(function(){
          window.location = href;
        }, 400);
      });
    </script>

That's far from ideal though, and it's much better to place the tracking code on the page you're going to navigate to. If you have control
over the page, then add the following code that checks the URL's hash.

    <script>
      if (window.location.hash.indexOf('_abbaTestComplete') != -1) {
        Abba('My Links').complete();
      }
    </script>

Then add the hash to the link's URL:

    <a href="/blog#_abbaTestComplete">

## Credits

Thanks to the following projects:

* https://github.com/assaf/vanity
* https://twitter.github.com/bootstrap
* http://buildingfirefoxos.com/
