# rate limit not to exceed 30 tweets/hour (method check in application controller)
json.error do
  json.message 'Rate limit exceeded (30 tweets/hour). Please try again later.'
end