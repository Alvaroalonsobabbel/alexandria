require 'rails_helper'

RSpec.describe 'Users', type: :request do
  include_context 'Skip Auth'

  let(:john) { create(:user) }
  let(:juan) { create(:juan) }
  let(:users) { [john, juan] }

  describe 'GET /api/users' do
    before { users }

    context 'default behaviour' do
      before { get '/api/users' }

      it 'receives HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives a json with the "data" root key' do
        expect(json_body['data']).to_not be nil
      end

      it 'receives 1 user' do
        expect(json_body['data'].size).to eq 3
      end
    end

    describe 'field picking' do
      context 'with the fillds parameter' do
        before { get '/api/users?fields=id,given_name,family_name' }

        it 'gets the user with only the id, given_name and family_name keys' do
          json_body['data'].each do |user|
            expect(user.keys).to eq %w[id given_name family_name]
          end
        end
      end

      context 'without the fields parameter' do
        before { get '/api/users' }

        it 'gets users with all the fields specified in the presenter' do
          json_body['data'].each do |user|
            expect(user.keys).to eq UserPresenter.build_attributes.map(&:to_s)
          end
        end
      end

      context 'with invalid field name givenname' do
        before { get '/api/users?fields=givenname' }

        it 'gets "400 Bad Request" back' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "fields=givenname" as an invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'fields=givenname'
        end
      end
    end

    describe 'pagination' do
      context 'when asking for the first page' do
        before { get '/api/users?page=1&per=1' }

        it 'receives HTTP status 200' do
          expect(response.status).to eq 200
        end

        it 'receives only one user' do
          expect(json_body['data'].size).to eq 1
        end

        it 'receives a response with the Link header' do
          expect(response.headers['Link'].split(', ').first).to eq(
            '<http://www.example.com/api/users?page=2&per=1>; rel="next"'
          )
        end
      end

      context 'when asking for the second page' do
        before { get '/api/users?page=2&per=1' }

        it 'receives HTTP response 200' do
          expect(response.status).to eq 200
        end

        it 'receives only one user' do
          expect(json_body['data'].size).to eq 1
        end
      end

      context 'when sending invalid "page" and "per" parameters' do
        before { get '/api/users?page=fake&per=10' }

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
      context 'with valid column name id' do
        it 'sorts user by "id desc"' do
          get '/api/users?sort=id&dir=desc'
          expect(json_body['data'].first['id']).to eq juan.id
        end
      end

      context 'with invalid column name fid' do
        before { get '/api/users?sort=fid&dir=asc' }

        it 'gets "400 Bad Request" back' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "sort=fid" as an invalid parameter' do
          expect(json_body['error']['invalid_params']).to eq 'sort=fid'
        end
      end
    end

    describe 'filtering' do
      context 'with valid filtering param "q[given_name_cont]=John"' do
        it 'receives "John Doe" back' do
          get '/api/users?q[given_name_cont]=John'
          expect(json_body['data'].first['id']).to eq john.id
          expect(json_body['data'].size).to eq 1
        end
      end

      context 'with invalid filter param "q[fgiven_name_cont]=John' do
        before { get '/api/users?q[fgiven_name_cont]=John' }

        it 'gets "400 Bad Request" back' do
          expect(response.status).to eq 400
        end

        it 'receives an error' do
          expect(json_body['error']).to_not be nil
        end

        it 'receives "q[fgiven_name_cont]=John" as an invalid param' do
          expect(json_body['error']['invalid_params']).to eq 'q[fgiven_name_cont]=John'
        end
      end
    end
  end

  describe 'GET /api/users/:id' do
    context 'with existing resource' do
      before { get "/api/users/#{john.id}" }

      it 'gets HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives the "John" user as JSON' do
        expected = { data: UserPresenter.new(john, {}).fields.embeds }
        expect(response.body).to eq(expected.to_json)
      end
    end

    context 'with nonexistent resource' do
      it 'gets HTTP status 404' do
        get '/api/users/581832481'
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST /api/users' do
    before { post '/api/users', params: { data: params } }

    context 'with valid parameters' do
      let(:params) do
        attributes_for(:juan)
      end

      it 'gets HTTP status 201' do
        expect(response.status).to eq 201
      end

      it 'receives the newly created resource' do
        expect(json_body['data']['given_name']).to eq 'Juan'
      end

      it 'adds a record in the database' do
        expect(User.count).to eq 2
      end

      it 'gets the new resource location in the Location header' do
        expect(response.headers['Location']).to eq(
          "http://www.example.com/api/users/#{User.last.id}"
        )
      end
    end

    context 'with invalid paramameters' do
      let(:params) { attributes_for(:user, email: '') }

      it 'gets HTTP status 422' do
        expect(response.status).to eq 422
      end

      it 'receives the error details' do
        expect(json_body['error']['invalid_params']).to eq(
          { 'email' => ["can't be blank", 'is invalid'] }
        )
      end

      it 'does not add a record in the database' do
        expect(User.count).to eq 1
      end
    end
  end

  describe 'PATCH /api/users/:id' do
    before { patch "/api/users/#{juan.id}", params: { data: params } }

    context 'with valid parameters' do
      let(:params) { { email: 'juanperez@email.com' } }

      it 'gets HTTP status 200' do
        expect(response.status).to eq 200
      end

      it 'receives the updated resource' do
        expect(json_body['data']['email']).to eq 'juanperez@email.com'
      end

      it 'updates the record in the database' do
        expect(User.last.email).to eq 'juanperez@email.com'
      end
    end

    context 'with invalid parameters' do
      let(:params) { { email: '' } }

      it 'gets HTTP status 422' do
        expect(response.status).to eq 422
      end

      it 'receives the error details' do
        expect(json_body['error']['invalid_params']).to eq(
          { 'email' => ["can't be blank", 'is invalid'] }
        )
      end
    end
  end

  describe 'DELETE /api/users/:id' do
    context 'with existing resource' do
      before { delete "/api/users/#{juan.id}" }

      it 'gets HTTP status 204' do
        expect(response.status).to eq 204
      end

      it 'deletes the user from the database' do
        expect(User.count).to eq 1
      end

      context 'with nonexistent resource' do
        it 'gets HTTP status 404' do
          delete '/api/users/2039482093'
          expect(response.status).to eq 404
        end
      end
    end
  end
end
