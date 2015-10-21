require 'fixman'
require 'minitest'
require 'classy_hash'

class TestConfiguration < Minitest::Test
  def test_validate_minimal_conf
    conf_params = {
      fixtures_base: 'hello',
      tasks: [
        {
          name: 'test_task',
          command: {
            action: 'wc',
          }
        }
      ],
    }

    assert_nil CH.validate(conf_params, Fixman::Configuration::CONF_SCHEMA)
  end
end
