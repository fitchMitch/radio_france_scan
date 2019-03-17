require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "graphql/client/railtie"
require "graphql/client/http"

Bundler.require(*Rails.groups)

module RadioFranceScan
  class Application < Rails::Application; end
  radio_france_url = 'https://openapi.radiofrance.fr/v1/graphql?x-token='
  access_token = Application.secrets.radio_france_access_token
  HTTPAdapter = GraphQL::Client::HTTP.new("#{radio_france_url}#{access_token}") do
    def headers(context)
      token = context[:'x-token'] || Application.secrets.radio_france_access_token
      fail "Missing RadioFranceScan access token" if token.nil?

      { "x-token" => token }
    end
  end

  Client = GraphQL::Client.new(
    schema: Application.root.join("db/schema.json").to_s,
    execute: HTTPAdapter
  )
  Application.config.graphql.client = Client
end
