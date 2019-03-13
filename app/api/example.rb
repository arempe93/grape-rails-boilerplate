# frozen_string_literal: true

module API
  class Example < API::Core
    params do
      optional :who, type: String, default: 'world'
    end
    get :example do
      { hello: params[:who] }
    end
  end
end
