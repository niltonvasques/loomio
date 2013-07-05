class ApplicationController < ActionController::Base
  include LocalesHelper
  protect_from_forgery

  before_filter :set_locale

  rescue_from CanCan::AccessDenied do |exception|
    request.env["HTTP_REFERER"] = root_url if request.env["HTTP_REFERER"].nil?
    flash[:error] = t("error.access_denied")
    redirect_to :back
  end
end
