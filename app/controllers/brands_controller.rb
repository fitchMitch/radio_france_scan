class BrandsController < ApplicationController
  # Define query for brand listing.
  #
  # All queries MUST be assigned to constants and therefore be statically
  # defined. Queries MUST NOT be generated at request time.
  IndexQuery = RadioFranceScan::Client.parse <<-'GRAPHQL'
    # All read requests are defined in a "query" operation
    query {
      # viewer is the currently authenticated User
      brands {
        id
        title
        baseline
        description
        websiteUrl
        liveStream
        localRadios{
          ...Views::Brands::LocalRadio::LocalRadio
        }
      }
    }
  GRAPHQL
  # ...Views::Brands::Index::LocalRadios

  # GET /brands
  def index
    data = query IndexQuery

    render "brands/index", locals: {
      brands: data.brands
    }
  end

  # Define query for brand show page.
  ShowQuery = RadioFranceScan::Client.parse <<-'GRAPHQL'
    query($id: StationsEnum!) {
      brand (id: $id) {
        id
        title
        baseline
        description
        websiteUrl
        liveStream
        localRadios{
          ...Views::Brands::LocalRadio::LocalRadio
        }
      }
    }
  GRAPHQL
  #
  # GET /brands/ID
  def show
    data = query ShowQuery, id: params[:id]
    logger.debug(data.brand)
    brand = data.brand
    if brand.present?
      render "brands/show", locals: {
        brands: [brand]
      }
    else
      # If node can't be found, 404. This may happen if the brand doesn't
      # exist, we don't have permission or we used a global ID that was the
      # wrong type.
      head :not_found
    end
  end
end
