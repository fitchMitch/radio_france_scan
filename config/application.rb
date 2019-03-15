require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "graphql/client/railtie"
require "graphql/client/http"

Bundler.require(*Rails.groups)

module RadioFranceScan
  class Application < Rails::Application
  end
  radio_france_url = 'https://openapi.radiofrance.fr/v1/graphql?x-token='
  access_token = Application.secrets.radio_france_access_token
  HTTPAdapter = GraphQL::Client::HTTP.new("#{radio_france_url}#{access_token}") do
    def headers(context)
      token = context[:access_token] || Application.secrets.radio_france_access_token
      if token.nil?
        # $ GITHUB_ACCESS_TOKEN=abc123 bin/rails server
        #   https://help.github.com/articles/creating-an-access-token-for-command-line-use
        fail "Missing RadioFranceScan access token"
      end

      { "x-token" => token }
    end
  end

  Client = GraphQL::Client.new(
    schema: Application.root.join("db/schema.json").to_s,
    execute: HTTPAdapter
  )
  Application.config.graphql.client = Client
end
