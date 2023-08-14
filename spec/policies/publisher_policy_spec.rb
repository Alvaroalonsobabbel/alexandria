require 'rails_helper'

describe PublisherPolicy do
  subject { described_class }

  permissions :index?, :show? do
    it 'grants access' do
      expect(subject).to permit(nil, Publisher.new)
    end
  end

  permissions :create?, :update?, :destroy? do
    it 'denies access if user is not admin' do
      expect(subject).not_to permit(build(:user), Publisher.new)
    end

    it 'grants access if user is admin' do
      expect(subject).to permit(build(:admin), Publisher.new)
    end
  end
end
