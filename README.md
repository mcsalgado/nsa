# Nsa

Nsa is an web app designed to snoop into all your RabbitMQ messages!

Sometimes when working with RabbitMQ you want to see the contents of the messages you're receiving to help with debugging, usually that
would involve checking logs or sometimes even changing the application code to output the message somewhere and that can get tiring rather quickly.

The goal of Nsa is to help with that, once you start the app it will create a queue that will subscribe to every message in every topic in your RabbitMQ instance. Once Nsa gets a message it will broadcast it to the frontend so we get the messages in realtime as they arrive!

To start Nsa:

  * Configure your dev.secret.exs with your RabbitMQ connection information
  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
