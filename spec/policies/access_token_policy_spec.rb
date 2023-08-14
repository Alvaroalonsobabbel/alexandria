require 'rails_helper'

describe AccessTokenPolicy do
  subject { described_class }

  permissions :create? do
    it 'grants access to create token without auth' do
      expect(subject).to permit(nil, AccessToken.new)
    end
  end
end
