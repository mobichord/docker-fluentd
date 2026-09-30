# Force the elasticsearch 8.x client. The Chainguard fluentd image also ships
# elasticsearch 9.x, whose compatible-with=9 headers Elastic Cloud 8.x rejects
# with a 400 (media_type_header_exception). The runtime image has no shell to
# delete the 9.x gems, so activate the 8.x ones before fluent-plugin-elasticsearch
# requires the client. Loaded via RUBYOPT=-r/opt/es-pin.rb.
gem 'elasticsearch', '8.18.1'
gem 'elasticsearch-api', '8.18.1'
