require 'test_helper'

class ProjectXmlTest < Minitest::Test
  def setup
    @redcap = Redcap.new
    @payload = @redcap.send(:build_payload,
                            content: :project_xml,
                            request_options: {
                              returnMetadataOnly: 'false',
                              exportSurveyFields: 'true',
                              exportDataAccessGroups: 'true',
                              returnFormat: 'json'
                            })
  end

  def test_payload_is_hash
    assert_instance_of Hash, @payload
  end

  def test_payload_has_project_xml
    assert_equal @payload[:content], :project_xml
  end
end
