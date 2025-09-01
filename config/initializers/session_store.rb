# Configure session store to work across subdomains
Rails.application.config.session_store :cookie_store,
  key: "_dashboard_app_session",
  domain: :all,  # This allows the session to work across all subdomains
  httponly: true,
  secure: Rails.env.production?
