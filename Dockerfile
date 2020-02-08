
FROM fluent/fluentd:v1.9-1 AS BASE

USER root

COPY /plugins /plugins

RUN apk add --update --virtual .build-deps sudo build-base ruby-dev git g++ musl-dev make openssl-dev  \
### Build and install custom plugins
 && sudo gem install eventmachine --platform ruby \
 && cd /plugins/fluent-plugin-rollbar && git init && git add . \
 && gem build fluent-plugin-rollbar \
 && sudo gem install fluent-plugin-rollbar-0.1.0.gem \
### Install regular plugins
 && sudo gem install fluent-plugin-elasticsearch \
 && sudo gem install fluent-plugin-record-reformer \
 && sudo gem install fluent-plugin-slack \
 && sudo gem install fluent-plugin-s3 \
 && sudo gem install fluent-plugin-grep \
 && sudo gem sources --clear-all \
 && sudo apk del .build-deps \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem \
## Install dependency for eventmachine
 && apk add --update libstdc++ libc6-compat openssl-dev \
 && ldd /usr/lib/ruby/gems/2.5.0/gems/eventmachine-1.2.7/lib/rubyeventmachine.so

USER fluent
