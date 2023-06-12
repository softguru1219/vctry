FROM ruby:2.6.3

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y build-essential nodejs yarn

ENV REDIS_URL $redis_url
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

RUN gem install bundler
COPY Gemfile* $APP_HOME/
RUN bundle install

COPY . $APP_HOME
RUN yarn install --check-files
RUN bundle exec rails webpacker:install
RUN RAILS_ENV=production bundle exec rake assets:precompile
CMD ["rails","server","-b","0.0.0.0"]
