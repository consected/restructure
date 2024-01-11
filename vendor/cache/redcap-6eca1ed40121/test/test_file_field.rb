require 'test_helper'

class FileFieldTest < Minitest::Test
  def setup
    @redcap = Redcap.new
    @payload = @redcap.send(:build_payload,
                            content: :file,
                            action: :export,
                            request_options: { field: 'signature', record: '33' })
  end

  def test_payload_is_hash
    assert_instance_of Hash, @payload
  end

  def test_payload_has_file
    assert_equal @payload[:content], :file
  end

  def test_payload_has_action
    assert_equal @payload[:action], :export
  end

  def test_payload_has_record
    assert_equal @payload[:record], '33'
  end
end
