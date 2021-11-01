
FROM fluent/fluentd:v1.14

USER root
RUN  apk add --update --virtual .build-deps \
        sudo build-base ruby-dev \
 && sudo gem install \
        fluent-plugin-elasticsearch \
 && sudo gem install \
        fluent-plugin-record-reformer \
 && sudo gem install fluent-plugin-teams \
 && sudo gem install fluent-plugin-s3 \
 && sudo gem install fluent-plugin-grep \
 && sudo gem sources --clear-all \
 && sudo apk del .build-deps \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem 

USER fluent
