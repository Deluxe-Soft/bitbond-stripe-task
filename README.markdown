# BitBond Stripe Connection - demonstation Task 

Demonstration of Stripe API calls.
Note - boilerplate of entire application (for simplicity) in order to avoid entire tedious reinventing wheel related to OAuth is fork of following repo: rfunduk/rails-stripe-connect-example (see for any cases of not obvious things).

## Setup

To get started, first clone this repo and install dependencies:

    bundle install
    bin/rake db:create:all
    bin/rake app:setup

Once you get through that, your keys will be in `config/secrets.yml` and
picked up by Rails when you start it.

Now load the schema into the database:

    bin/rake db:schema:load