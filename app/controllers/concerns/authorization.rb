module Authorization
  extend ActiveSupport::Concern
  include Pundit::Authorization

  included do
    rescue_from Pundit::NotAuthorizedError, with: :forbidden
    after_action :verify_authorized
  end

  def authorize_actions
    return authorize(controller_name.classify.constantize) if action_name == 'index'

    authorize resource
  end

  def forbidden
    render(status: 403)
  end
end
