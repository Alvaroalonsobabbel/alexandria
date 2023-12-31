require 'rails_helper'

RSpec.describe 'Authors', type: :request do
  include_context 'Skip Auth'

  let(:pat) { create(:author) }
  let(:michael) { create(:michael_hartl) }
  let(:sam) { create(:sam_ruby) }
  let(:authors) { [pat, michael, sam] }

  describe 'GET /api/authors' do
    before { authors }

    context 'default behavior' do
      before { get '/api/authors' }

      it 'receives HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives a json with the "data" root key' do
        expect(json_body['data']).to_not be nil
      end

      it 'receives all 3 books' do
        expect(json_body['data'].count).to eq 3
      end
    end

    describe 'field picking' do
      context 'with the fields parameter' do
        before { get '/api/authors?fields=id,given_name,family_name' }

        it 'gets author with only the id, given_name and family_name keys' do
          json_body['data'].each do |author|
            expect(author.keys).to eq %w[id given_name family_name]
          end
        end
      end

      context 'without the field parameter' do
        before { get '/api/authors' }

        it 'gets authors with all the fields specified in the presenter' do
          json_body['data'].each do |author|
            expect(author.keys).to eq AuthorPresenter.build_attributes.map(&:to_s)
          end
        end
      end

      context 'with invalid field name "fid"' do
        before { get '/api/authors?fields=fid,given_name,family_name' }
        it 'gets "400 Bad Request" back' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "fields=fid" as an invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'fields=fid'
        end
      end
    end

    describe 'pagination' do
      context 'when asking for the first page' do
        before { get '/api/authors?page=1&per=2' }

        it 'receives HTTP status 200' do
          expect(response.status).to eq 200
        end

        it 'receives only two authors' do
          expect(json_body['data'].size).to eq 2
        end

        it 'receives a response with the Link header' do
          expect(response.headers['Link'].split(', ').first).to eq(
            '<http://www.example.com/api/authors?page=2&per=2>; rel="next"'
          )
        end
      end

      context 'when asking for the second page' do
        before { get '/api/authors?page=2&per=2' }

        it 'receives HTTP status 200' do
          expect(response.status).to eq 200
        end

        it 'receives only one author' do
          expect(json_body['data'].size).to eq 1
        end
      end

      context 'when sending invalid "page" and "per" parameters' do
        before { get '/api/authors?page=fake&per=10' }

        it 'receives HTTP status 400' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "page=fake as an invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'page=fake'
        end
      end
    end

    describe 'sorting' do
      context 'with valid column name "id"' do
        it 'sorts the author by id desc' do
          get '/api/authors?sort=id&dir=desc'

          expect(json_body['data'].first['id']).to eq sam.id
          expect(json_body['data'].last['id']).to eq pat.id
        end
      end

      context 'with invalid column name "fid"' do
        before { get '/api/authors?sort=fid&dir=desc' }

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
      context 'with valid filtering param "q[given_name_cont]=Pat"' do
        it 'receives "Pat" back' do
          get '/api/authors?q[given_name_cont]=Pat'
          expect(json_body['data'].first['id']).to eq pat.id
          expect(json_body['data'].size).to eq 1
        end

        context 'with invalid filtering param "q[fgiven_name_cont]=Pat"' do
          before { get '/api/authors?q[fgiven_name_cont]=Pat' }

          it 'gets "400 Bad Request" back' do
            expect(response.status).to eq 400
          end

          it 'receives an error' do
            expect(json_body['error']).to_not be nil
          end

          it 'receives "q[fgiven_name_cont]=Pat" as an invalid param' do
            expect(json_body['error']['invalid_params']).to eq 'q[fgiven_name_cont]=Pat'
          end
        end
      end
    end
  end

  describe 'GET /api/authors/:id' do
    context 'with existing resource' do
      before { get "/api/authors/#{pat.id}" }

      it 'gets HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives the "Pat" author as JSON' do
        expected = { data: AuthorPresenter.new(pat, {}).fields.embeds }
        expect(response.body).to eq(expected.to_json)
      end
    end

    context 'with nonexistent resource' do
      it 'gets HTTP status 404' do
        get '/api/authors/2124124'
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST /api/authors' do
    before { post '/api/authors', params: { data: params } }

    context 'with valid parameters' do
      let(:params) { attributes_for(:author) }

      it 'gets HTTP Status 201' do
        expect(response.status).to eq 201
      end

      it 'receives the newly created resource' do
        expect(json_body['data']['given_name']).to eq 'Pat'
      end

      it 'adds a record in the database' do
        expect(Author.count).to eq 1
      end

      it 'gets the new resource location in the Location header' do
        expect(response.header['Location']).to eq(
          "http://www.example.com/api/authors/#{Author.first.id}"
        )
      end
    end

    context 'with invalid parameters' do
      let(:params) { attributes_for(:author, given_name: '') }

      it 'gets HTTP status 422' do
        expect(response.status).to eq 422
      end

      it 'receives the error details' do
        expect(json_body['error']['invalid_params']).to eq(
          { 'given_name' => ["can't be blank"] }
        )
      end

      it 'does not add a record in the database' do
        expect(Author.count).to eq 0
      end
    end
  end

  describe 'PATCH /api/authors/:id' do
    before { patch "/api/authors/#{pat.id}", params: { data: params } }

    context 'with valid parameters' do
      let(:params) { { given_name: 'Patrick' } }

      it 'gets HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives the updated resource' do
        expect(json_body['data']['given_name']).to eq 'Patrick'
      end

      it 'updates the record in the database' do
        expect(Author.first.given_name).to eq 'Patrick'
      end
    end

    context 'with invalid parameters' do
      let(:params) { { given_name: '' } }

      it 'gets HTTP status 422' do
        expect(response.status).to eq 422
      end

      it 'receives the error details' do
        expect(json_body['error']['invalid_params']).to eq(
          { 'given_name' => ["can't be blank"] }
        )
      end

      it 'does not add the record in the database' do
        expect(Author.first.given_name).to eq 'Pat'
      end
    end
  end

  describe 'DELETE /api/authors/:id' do
    context 'with existing resource' do
      before { delete "/api/authors/#{pat.id}" }

      it 'gets HTTP status 204' do
        expect(response.status).to eq 204
      end

      it 'deletes the author from the database' do
        expect(Author.count).to eq 0
      end
    end

    context 'with nonexistent resource' do
      it 'gets HTTP status 404' do
        delete '/api/authors/123123123'
        expect(response.status).to eq 404
      end
    end
  end
end
