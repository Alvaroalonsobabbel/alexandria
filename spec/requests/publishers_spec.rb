require 'rails_helper'

RSpec.describe 'Publishers', type: :request do
  include_context 'Skip Auth'

  let(:oreilly) { create(:publisher) }
  let(:dev_media) { create(:dev_media) }
  let(:super_books) { create(:super_books) }
  let(:publishers) { [oreilly, dev_media, super_books] }

  describe 'GET /api/publishers' do
    before { publishers }

    context 'default behavior' do
      before { get '/api/publishers' }

      it 'receives HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives a json with the "Data" root key' do
        expect(json_body['data']).to_not be nil
      end

      it 'receives all 3 publishers' do
        expect(json_body['data'].count).to eq 3
      end
    end

    describe 'field picking' do
      context 'with the fields parameter' do
        before { get '/api/publishers?fields=id,name' }

        it 'gets the publisher with only the id and the name' do
          json_body['data'].each do |publisher|
            expect(publisher.keys).to eq %w[id name]
          end
        end
      end

      context 'without the field parameter' do
        before { get '/api/publishers' }

        it 'gets publishers with all the field specified in the presenter' do
          json_body['data'].each do |publisher|
            expect(publisher.keys).to eq PublisherPresenter.build_attributes.map(&:to_s)
          end
        end
      end

      context 'with invalid field name "fid"' do
        before { get '/api/publishers?fields=fid,name' }

        it 'gets "400 Bad Request" back' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "fields=fid" as the invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'fields=fid'
        end
      end
    end

    describe 'pagination' do
      context 'when asking for the first page' do
        before { get '/api/publishers?page=1&per=2' }

        it 'receives HTTP status 200' do
          expect(response.status).to eq 200
        end

        it 'receives only two publishers' do
          expect(json_body['data'].count).to eq 2
        end

        it 'receives a response with the Link header' do
          expect(response.headers['Link'].split(', ').first).to eq(
            '<http://www.example.com/api/publishers?page=2&per=2>; rel="next"'
          )
        end
      end

      context 'when asking for the second page' do
        before { get '/api/publishers?page=2&per=2' }

        it 'receives HTTP status 200' do
          expect(response.status).to eq 200
        end

        it 'receives only one publisher' do
          expect(json_body['data'].count).to eq 1
        end
      end

      context 'when sending invalid "page" and "per" parameters' do
        before { get '/api/publishers?page=fake&per=10' }

        it 'receives HTTP status 400' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "page=fake" as an invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'page=fake'
        end
      end
    end

    describe 'sorting' do
      context 'with valid column name "id"' do
        it 'sorts the publisher by id desc' do
          get '/api/publishers?sort=id&dir=desc'

          expect(json_body['data'].first['id']).to eq super_books.id
          expect(json_body['data'].last['id']).to eq oreilly.id
        end
      end

      context 'with invalid column name "fid"' do
        before { get '/api/publishers?sort=fid&dir=desc' }

        it 'gets 400 Bad Request error' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "sort=fid" as an invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'sort=fid'
        end
      end
    end

    describe 'filtering' do
      context 'with valid filtering param "q[name_cont]=Reilly"' do
        it "receives O'Reilly back" do
          get '/api/publishers?q[name_cont]=Reilly'

          expect(json_body['data'].first['id']).to eq oreilly.id
          expect(json_body['data'].size).to eq 1
        end
      end

      context 'with invalid filtering param "q[fname_cont]=Reilly"' do
        before { get '/api/publishers?q[fname_cont]=Reilly' }

        it 'gets 400 Bad Request back' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "q[fname_cont]=Reilly" as an invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'q[fname_cont]=Reilly'
        end
      end
    end
  end

  describe 'GET /api/publishers/:id' do
    context 'with existing resource' do
      before { get "/api/publishers/#{oreilly.id}" }

      it 'gets HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives the "ORielly publisher as JSON' do
        expected = { data: PublisherPresenter.new(oreilly, {}).fields.embeds }
        expect(response.body).to eq(expected.to_json)
      end
    end

    context 'with nonexistent resource' do
      it 'gets HTTP status 404' do
        get '/api/publishers/123123'
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST /api/publishers' do
    before { post '/api/publishers', params: { data: params } }

    context 'with valid parameters' do
      let(:params) { attributes_for(:publisher) }

      it 'gets HTTP status 201' do
        expect(response.status).to eq 201
      end

      it 'receives the newly created resource' do
        expect(json_body['data']['name']).to eq 'O\'Reilly'
      end

      it 'adds the record to the database' do
        expect(Publisher.count).to eq 1
      end

      it 'gets the new resource location in the Location header' do
        expect(response.header['Location']).to eq(
          "http://www.example.com/api/publishers/#{Publisher.first.id}"
        )
      end
    end

    context 'with invalid parameters' do
      let(:params) { attributes_for(:publisher, name: '') }

      it 'gets HTTP status 422' do
        expect(response.status).to eq 422
      end

      it 'receives the error detail' do
        expect(json_body['error']['invalid_params']).to eq(
          { 'name' => ["can't be blank"] }
        )
      end

      it 'does not add a record to the database' do
        expect(Publisher.count).to eq 0
      end
    end
  end

  describe 'PATCH /api/publishers/:id' do
    before { patch "/api/publishers/#{oreilly.id}", params: { data: params } }

    context 'with valid parameters' do
      let(:params) { { name: 'Orilley' } }

      it 'gets HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives the updated respource' do
        expect(json_body['data']['name']).to eq 'Orilley'
      end

      it 'updates the record in the database' do
        expect(Publisher.first.name).to eq 'Orilley'
      end
    end

    context 'with invalid parameters' do
      let(:params) { { name: '' } }

      it 'gets HTTP status 422' do
        expect(response.status).to eq 422
      end

      it 'receives the error detail' do
        expect(json_body['error']['invalid_params']).to eq(
          { 'name' => ["can't be blank"] }
        )
      end

      it 'does not add the record in the database' do
        expect(Publisher.first.name).to eq 'O\'Reilly'
      end
    end
  end

  describe 'DELETE /api/publishers/:id' do
    context 'with existing resource' do
      before { delete "/api/publishers/#{oreilly.id}" }

      it 'gets HTTP status 204' do
        expect(response.status).to eq 204
      end

      it 'deletes the publisher from the database' do
        expect(Publisher.count).to eq 0
      end
    end

    context 'with nonexistent resource' do
      it 'gets HTTP status 404' do
        delete '/api/publishers/123235234'
        expect(response.status).to eq 404
      end
    end
  end
end
