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

  def test_condition_schema_validation
    schema = { condition: Fixman::Configuration::CONDITION_OR_CLEANUP_SCHEMA }

    valid = {
      condition: {
        type: :ruby,
        action: 'proc {}'
      }
    }
    cond = valid[:condition]
    assert_nil(CH.validate valid, schema)

    cond[:type] = :shell
    cond[:action] = 'wc'
    assert_nil(CH.validate valid, schema)

    cond.delete :type
    assert_raises(RuntimeError) { CH.validate valid, schema }

    cond[:type] = :something_else
    assert_raises(RuntimeError) { CH.validate valid, schema }

    cond[:type] = :ruby
    cond[:action] = 'not a proc'
    assert_raises(RuntimeError) { CH.validate valid, schema }

    cond[:type] = :ruby
    cond[:action] = 'proc {}'
    cond[:exit_status] = 300
    assert_nil CH.validate valid, schema

    cond[:type] = :shell
    cond[:action] = 'wc'
    cond[:exit_status] = 300
    assert_raises(RuntimeError) { CH.validate valid, schema }
  end
end
