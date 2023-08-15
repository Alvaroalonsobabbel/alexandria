class UserPresenter < BasePresenter
  cached
  FIELDS = %i[id email given_name family_name role last_logged_in_at
              confirmed_at confirmation_sent_at reset_password_sent_at
              created_at updated_at]

  related_to :access_tokens
  sort_by(*FIELDS)
  filter_by(*FIELDS)
  build_with(*[FIELDS.push(%i[confirmation_token reset_password_token
                              reset_password_redirect_url confirmation_redirect_url])].flatten)
end

# confirmation_redirect_url
