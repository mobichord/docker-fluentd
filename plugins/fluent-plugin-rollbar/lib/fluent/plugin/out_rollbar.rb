#
# Copyright 2020- darknode
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/output'
require 'eventmachine'
require 'em-http-request'

module Fluent
  module Plugin
    class RollbarOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output('rollbar', self)

      DEFAULT_BUFFER_TYPE = 'memory'.freeze

      config_param :tokens, :hash, default: {}, value_type: :string
      config_param :endpoint, :string, default: 'https://api.rollbar.com/api/1/item/'
      config_section :buffer do
        config_set_default :type, DEFAULT_BUFFER_TYPE
        config_set_default :flush_mode, :interval
        config_set_default :flush_interval, 1
      end

      def configure(conf)
        super
      end

      def start
        super
      end

      def shutdown
        super
      end

      def format(tag, time, record)
        [tag, time, record].to_msgpack
      end

      def formatted_to_msgpack_binary?
        true
      end

      def multi_workers_ready?
        true
      end

      def prefer_delayed_commit
        false
      end

      def write(chunk)
        chunk.msgpack_each do |(_tag, _time, record)|
          payload = create_payload(record)
          next if payload.nil?

          log.warn JSON.dump(payload)
          EventMachine.run do
            req = EventMachine::HttpRequest.new(@endpoint).post(body: payload.to_json)
            req.callback do
              if req.response_header.status != 200
                log.warn "rollbar: Got unexpected status code from Rollbar.io api: #{req.response_header.status}"
                log.warn "rollbar: Response: #{req.response}"
              end
              EventMachine.stop
            end

            req.errback do
              log.warn "rollbar: Call to API failed, status code: #{req.response_header.status}"
              log.warn "rollbar: Error's response: #{req.response}"
              EventMachine.stop
            end
          end
        end

        commit_write(chunk.unique_id)
      rescue Exception => e
        log.warn "rollbar: #{e}"
      end

      def create_payload(record)
        return nil unless record.key?('application')

        app = record['application']
        app = app[(app.index('.') || -1) + 1..-1]
        return nil if !@tokens.key?(app) || record['level'] != 'ERROR'

        {
          access_token: @tokens[app],
          data: {
            environment: record['subsystem'] || 'None',
            level: 'error',
            platform: 'linux',
            language: 'java',
            framework: 'SprintBoot',
            custom: {
              activityId: record['activityId'],
              tenant: record.key?('tenant') ? record['tenant'] : record['tenantCode'],
              app: app,
              logger: record['logger']
            },
            body: { message: { body: record['message'] } }
          }
        }
      end
    end
  end
end
