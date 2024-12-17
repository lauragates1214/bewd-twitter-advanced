require 'rails_helper'

RSpec.describe TweetsController, type: :controller do
  render_views

  context 'POST /tweets' do
    it 'renders new tweet object' do
      user = FactoryBot.create(:user)
      session = user.sessions.create
      @request.cookie_jar.signed['twitter_session_token'] = session.token

      post :create, params: {
        tweet: {
          message: 'Test Message'
        }
      }

      expect(response.body).to eq({
        tweet: {
          username: user.username,
          message: 'Test Message'
        }
      }.to_json)

      expect(JSON.parse(response.body)['tweet']['message']).to eq('Test Message')
      expect(JSON.parse(response.body)['tweet']['image']).to eq(nil)
    end

    it 'OK with image attachments' do
      user = FactoryBot.create(:user)
      session = user.sessions.create
      @request.cookie_jar.signed['twitter_session_token'] = session.token

      post :create, params: {
        tweet: {
          message: 'Test Message',
          image: fixture_file_upload('test.png')
        }
      }

      expect(JSON.parse(response.body)['tweet']['message']).to eq('Test Message')
      expect(JSON.parse(response.body)['tweet']['image']).to include('test.png')
    end

    # rate limit test
    it 'OK rate limit: 30 tweets per hour' do
      # create a user
      user = FactoryBot.create(:user)
      # create a session for the user
      session = user.sessions.create
      # set the session token in the cookie, so user logged in in front-end
      @request.cookie_jar.signed['twitter_session_token'] = session.token

      # create 30 tweets for the user (max), so next one will fail
      30.times do |i|
        FactoryBot.create(:tweet, user: user)
      end

      # check that user has 30 tweets
      expect(user.tweets.count).to eq(30)

      # make the POST request
      post :create, params: {
        tweet: {
          message: 'Test Message'
        }
      }

      # check that user still has 30 tweets
      expect(user.tweets.count).to eq(30)

      # check that the response is correct
      expect(JSON.parse(response.body)['error']['message']).to eq('Rate limit exceeded (30 tweets/hour). Please try again later.')
    end
  end

  context 'GET /tweets' do
    it 'renders all tweets object' do
      user = FactoryBot.create(:user)
      FactoryBot.create(:tweet, user: user)
      FactoryBot.create(:tweet, user: user)

      get :index

      expect(response.body).to eq({
        tweets: [
          {
            id: Tweet.order(created_at: :desc)[0].id,
            username: user.username,
            message: 'Test Message',
            image: nil
          }, {
            id: Tweet.order(created_at: :desc)[1].id,
            username: user.username,
            message: 'Test Message',
            image: nil
          }
        ]
      }.to_json)
    end
  end

  context 'DELETE /tweets/:id' do
    it 'renders success' do
      user = FactoryBot.create(:user)
      session = user.sessions.create
      @request.cookie_jar.signed['twitter_session_token'] = session.token

      tweet = FactoryBot.create(:tweet, user: user)

      delete :destroy, params: { id: tweet.id }

      expect(response.body).to eq({ success: true }.to_json)
      expect(user.tweets.count).to eq(0)
    end

    it 'renders fails if not logged in' do
      user = FactoryBot.create(:user)
      tweet = FactoryBot.create(:tweet, user: user)

      delete :destroy, params: { id: tweet.id }

      expect(response.body).to eq({ success: false }.to_json)
      expect(user.tweets.count).to eq(1)
    end
  end

  context 'GET /users/:username/tweets' do
    it 'renders tweets by username' do
      user1 = FactoryBot.create(:user, username: 'user1', email: 'user1@user.com')
      user2 = FactoryBot.create(:user, username: 'user2', email: 'user2@user.com')

      tweet1 = FactoryBot.create(:tweet, user: user1)
      FactoryBot.create(:tweet, user: user2)

      get :index_by_user, params: { username: user1.username }

      expect(response.body).to eq({
        tweets: [
          {
            id: tweet1.id,
            username: user1.username,
            message: 'Test Message',
            image: nil
          }
        ]
      }.to_json)
    end

    it 'renders tweets with images by username' do
      user1 = FactoryBot.create(:user, username: 'user1', email: 'user1@user.com')
      user2 = FactoryBot.create(:user, username: 'user2', email: 'user2@user.com')

      FactoryBot.create(:tweet, user: user1, image: fixture_file_upload('test.png'))
      FactoryBot.create(:tweet, user: user2, image: fixture_file_upload('test.png'))

      get :index_by_user, params: { username: user1.username }

      expect(JSON.parse(response.body)['tweets'].first['image']).to include('test.png')
    end
  end
end
