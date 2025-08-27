class DebugController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_company
  
  def subdomain_test
    render json: {
      host: request.host,
      subdomain: request.subdomain,
      domain: request.domain,
      port: request.port,
      full_url: request.url,
      headers_host: request.headers['HTTP_HOST'],
      tld_length: Rails.application.config.action_dispatch.tld_length,
      host_with_port: request.host_with_port,
      subdomains: request.subdomains
    }
  end
end