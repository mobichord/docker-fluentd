require "helper"
require "fluent/plugin/out_rollbar.rb"

class RollbarOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  private

  CONFIG = %(
    tokens {
      "prefix.app1": "app1",
      "app2": "app2"
    }
  ).freeze

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::RollbarOutput).configure(conf)
  end

  sub_test_case 'configuration' do
    test 'tokens should be valid hash' do
      d = create_driver
      assert_equal 2, d.instance.tokens.length
      assert_equal 'app2', d.instance.tokens['app2']
    end
  end

  sub_test_case 'payload' do
    test 'should skip event if token not found' do

      d = create_driver
      payload = d.instance.create_payload({})

      assert_nil payload
    end
    test 'should skip event if level not ERROR' do

      d = create_driver
      payload = d.instance.create_payload('application': 'app2')

      assert_nil payload
    end
    test 'should find token by application' do

      message = {
        'application' => 'app2',
        'level' => 'ERROR'
      }

      d = create_driver
      payload = d.instance.create_payload(message)

      assert_not_nil payload
    end
    test 'should return rollbar ready payload' do

      message = {
        'application' => 'app2',
        'level' => 'ERROR',
        'subsystem' => 'test',
        'activityId' => '123123',
        'tenant' => 'test',
        'logger' => 'method1',
        'message' => 'ERROR'
      }

      d = create_driver
      payload = d.instance.create_payload(message)

      assert_not_nil payload

      pretty_json = JSON.pretty_generate(payload)

      assert_equal '{
  "access_token": "app2",
  "data": {
    "environment": "test",
    "level": "error",
    "platform": "linux",
    "language": "java",
    "framework": "SprintBoot",
    "custom": {
      "activityId": "123123",
      "tenant": "test",
      "app": "app2",
      "logger": "method1"
    },
    "body": {
      "message": {
        "body": "ERROR"
      }
    }
  }
}', pretty_json
    end
  end
end
