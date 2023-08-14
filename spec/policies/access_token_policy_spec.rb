require 'rails_helper'

describe AccessTokenPolicy do
  subject { described_class }

  permissions :create? do
    it 'grants access to create token without auth' do
      expect(subject).to permit(nil, AccessToken.new)
    end
  end

  permissions :destroy? do
    it 'grants the user of the token access to destroy it' do
      user = User.new
      expect(subject).to permit(user, AccessToken.new(user: user))
    end
  end
end
