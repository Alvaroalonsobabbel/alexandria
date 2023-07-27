require 'rails_helper'

RSpec.describe EagerLoader do
  let(:ruby_microscope) { create(:ruby_microscope) }
  let(:rails_tutorial) { create(:ruby_on_rails_tutorial) }
  let(:agile_web_dev) { create(:agile_web_development) }
  let(:books) { [ruby_microscope, rails_tutorial, agile_web_dev] }

  let(:scope) { Book.all }
  let(:params) { {} }
  let(:eager_loader) { EagerLoader.new(scope, params) }
  let(:loaded) { eager_loader.load }

  before do
    allow(BookPresenter).to(
      receive(:relations).and_return(%w[author publisher])
    )
    books
  end

  describe '#load' do
    context 'without any parameters' do
      it 'returns the scope unchanged' do
        expect(loaded).to eq scope
      end
    end

    context 'with invalid embed params' do
      let(:params) { { embed: 'authorr' } }

      it 'with invalid relations with "embed"' do
        expect { loaded }.to raise_error(QueryBuilderError)
      end
    end

    context 'with invalid include params' do
      let(:params) { { include: 'pubilsher' } }

      it 'with invalid relations with "embed"' do
        expect { loaded }.to raise_error(QueryBuilderError)
      end
    end
  end
end
