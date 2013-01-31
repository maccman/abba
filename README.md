# Abba

Abba is a simple a/b testing framework

* Multi variant support
* Simple JavaScript API
* Filter results by date and browser

## Heroku 10 seconds setup

    heroku create myapp
    heroku addons:add mongohq:sandbox
    git push heroku master
    heroku open

## A/B testing API

    <script src="//localhost:4050/v1/abba.js"></script>

    <script>
      Abba('test name')
        .control(function(){ /* ... */ })
        .variant('test b', function(){ /* ... */ })
        .start();
    </script>

    <script>
      // On successful conversion
      Abba('test name').complete();
    </script>

## Example test

Examples are under `./public/test`.

## Running locally

Requirements:

* Ruby 1.9.3
* Mongo

Setup:

    bundle install
    thin start