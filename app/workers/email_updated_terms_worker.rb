class EmailUpdatedTermsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'afterwards'
  sidekiq_options backtrace: true
  sidekiq_options retry: false

  def perform
    if redis.llen(enqueued_emails_key) > 0
      begin
        user_id = redis.lpop enqueued_emails_key
        user = User.find(user_id)
        CustomerMailer.updated_terms_email(user).deliver_now
      rescue => e
        # rpush so that if we run into an error, we don't keep running the exact same one
        redis.rpush(enqueued_emails_key, user_id)
        raise e
      end
    end
  end

  def enqueued_emails_key
    "#{Rails.env[0..2]}_email_updated_terms_user_ids"
  end

  def redis
    Redis.current
  end
end
