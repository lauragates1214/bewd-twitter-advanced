class TweetsController < ApplicationController
  def index
    @tweets = Tweet.all.order(created_at: :desc)
    render 'tweets/index'
  end

  def create
    # current_user in application controller (now reusable)
    # pass_rate_limit in User model
    # rate_limit_error in jbuilder under tweets/
    # TweetMailer.notify in Tweet model
    if !current_user.pass_rate_limit?
      return render 'tweets/rate_limit_error'
    end

    # successfully passed conditions
    @tweet = current_user.tweets.new(tweet_params)

    if @tweet.save
      # notify_via_email method in Tweet model
      render 'tweets/create', status: 201
    end
  end

  def destroy
    token = cookies.signed[:twitter_session_token]
    session = Session.find_by(token: token)

    return render json: { success: false } unless session

    user = session.user
    tweet = Tweet.find_by(id: params[:id])

    if tweet && (tweet.user == user) && tweet.destroy
      render json: {
        success: true
      }
    else
      render json: {
        success: false
      }
    end
  end

  def index_by_user
    user = User.find_by(username: params[:username])

    if user
      @tweets = user.tweets
      render 'tweets/index'
    end
  end

  private

  def tweet_params
    params.require(:tweet).permit(:message, :image)
  end
end
