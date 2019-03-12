Rails.application.config.middleware.delete ActionDispatch::RequestId
Rails.application.config.middleware.insert_after RequestStore::Middleware, Middleware::RequestId
