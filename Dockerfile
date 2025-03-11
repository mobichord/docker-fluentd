# Use a newer Alpine-based Fluentd image
FROM fluent/fluentd:v1.17.1-1.1 AS BASE

USER root

COPY /plugins /plugins

# Update package manager and install dependencies
RUN apk add --update --virtual .build-deps sudo build-base ruby-dev git g++ musl-dev make openssl-dev \
    && apk add --update libstdc++ libc6-compat openssl-dev \
    
    # Upgrade Ruby (Alpine packages may install Ruby 3.x)
    && apk add --no-cache ruby ruby-dev \
    
    # Install Fluentd plugins including CloudWatch Logs
    && sudo gem install eventmachine --platform ruby \
    && sudo gem install fluent-plugin-elasticsearch \
    && sudo gem install fluent-plugin-record-reformer \
    && sudo gem install fluent-plugin-slack \
    && sudo gem install fluent-plugin-s3 \
    && sudo gem install fluent-plugin-grep \
    && sudo gem install fluent-plugin-cloudwatch-logs \
    
    # Build and install custom Fluentd plugin
    && cd /plugins/fluent-plugin-rollbar && git init && git add . \
    && gem build fluent-plugin-rollbar \
    && sudo gem install fluent-plugin-rollbar-0.1.0.gem \
    
    # Clean up unnecessary packages and cache
    && sudo gem sources --clear-all \
    && sudo apk del .build-deps \
    && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem \
    
    # Verify Ruby and Fluentd plugin installation
    && ruby -v \
    && fluent-gem list

USER fluent
