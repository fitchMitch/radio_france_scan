class BrandsController < ApplicationController
  # Define query for brand listing.
  #
  # All queries MUST be assigned to constants and therefore be statically
  # defined. Queries MUST NOT be generated at request time.
  IndexQuery = RadioFranceScan::Client.parse <<-'GRAPHQL'
    # All read requests are defined in a "query" operation
    query {
      # viewer is the currently authenticated User
      viewer {
        # "...FooConstant" is the fragment spread syntax to include the index
        # view's fragment.
        #
        # "Views::Brands::Index::Viewer" means the fragment is defined
        # in app/views/brands/index.html.erb and named Viewer.
        ...Views::Brands::Index::Viewer
      }
    }
  GRAPHQL

  # GET /brands
  def index
    # Use query helper defined in ApplicationController to execute the query.
    # `query` returns a GraphQL::Client::QueryResult instance with accessors
    # that map to the query structure.
    data = query IndexQuery

    # Render the app/views/brands/index.html.erb template with our
    # current User.
    #
    # Using explicit render calls with locals is preferred to implicit render
    # with instance variables.
    render "brands/index", locals: {
      viewer: data.viewer
    }
  end


  # Define query for "Show more brands..." AJAX action.
  MoreQuery = RadioFranceScan::Client.parse <<-'GRAPHQL'
    # This query uses variables to accept an "after" param to load the next
    # 10 brands.
    query($after: String!) {
      viewer {
        brands(first: 10, after: $after) {
          # Instead of refetching all of the index page's data, we only need
          # the data for the brands container partial.
          ...Views::Brands::Brands::BrandConnection
        }
      }
    }
  GRAPHQL

  # GET /brands/more?after=CURSOR
  def more
    # Execute the MoreQuery passing along data from params to the query.
    data = query MoreQuery, after: params[:after]

    # Using an explicit render again, just render the brands list partial
    # and return it to the client.
    render partial: "brands/brands", locals: {
      brands: data.viewer.brands
    }
  end


  # Define query for brand show page.
  ShowQuery = RadioFranceScan::Client.parse <<-'GRAPHQL'
    # Query is parameterized by a $id variable.
    query($id: ID!) {
      # Use global id Node lookup
      node(id: $id) {
        # Include fragment for app/views/brands/show.html.erb
        ...Views::Brands::Show::Brand
      }
    }
  GRAPHQL

  # GET /brands/ID
  def show
    # Though we've only defined part of the ShowQuery in the controller, when
    # query(ShowQuery) is executed, we're sending along the query as well as
    # all of its fragment dependencies to the API server.
    #
    # Here's the raw query that's actually being sent.
    #
    # query BrandsController__ShowQuery($id: ID!) {
    #   node(id: $id) {
    #     ...Views__Brands__Show__Brand
    #   }
    # }
    #
    # fragment Views__Brands__Show__Brand on Brand {
    #   id
    #   owner {
    #     login
    #   }
    #   name
    #   description
    #   homepageUrl
    #   ...Views__Brands__Navigation__Brand
    # }
    #
    # fragment Views__Brands__Navigation__Brand on Brand {
    #   hasIssuesEnabled
    # }
    data = query ShowQuery, id: params[:id]

    if brand = data.node
      render "brands/show", locals: {
        brand: brand
      }
    else
      # If node can't be found, 404. This may happen if the brand doesn't
      # exist, we don't have permission or we used a global ID that was the
      # wrong type.
      head :not_found
    end
  end

  StarMutation = RadioFranceScan::Client.parse <<-'GRAPHQL'
    mutation($id: ID!) {
      star(input: { starrableId: $id }) {
        starrable {
          ...Views::Brands::Star::Brand
        }
      }
    }
  GRAPHQL

  def star
    data = query StarMutation, id: params[:id]

    if brand = data.star
      respond_to do |format|
        format.js {
          render partial: "brands/star", locals: { brand: data.star.starrable }
        }

        format.html {
          redirect_to "/brands"
        }
      end
    else
      head :not_found
    end
  end

  UnstarMutation = RadioFranceScan::Client.parse <<-'GRAPHQL'
    mutation($id: ID!) {
      unstar(input: { starrableId: $id }) {
        starrable {
          ...Views::Brands::Star::Brand
        }
      }
    }
  GRAPHQL

  def unstar
    data = query UnstarMutation, id: params[:id]

    if brand = data.unstar
      respond_to do |format|
        format.js {
          render partial: "brands/star", locals: { brand: data.unstar.starrable }
        }

        format.html {
          redirect_to "/brands"
        }
      end
    else
      head :not_found
    end
  end
end
