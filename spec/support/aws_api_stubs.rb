# frozen_string_literal: true

#
# Setup WebMock stubs for AWS API calls, allowing them to act
# provide consistent results and work without an AWS_PROFILE being set.
# By default, stubs are used. 
# To test against the live AWS API, ensure the environment variable `NO_AWS_MOCKS=true`
# is set
module AwsApiStubs
  def setup_stub(type, result: nil)
    return if ENV['NO_AWS_MOCKS'] == 'true'

    # puts 'Stubbing AWS API calls'
    setup_default_aws_stubs
    use = requests_responses[type]
    use[result: result] if result
    use[:result] = use[:result].to_json if use[:result].is_a? Hash

    setup_webmock_stub(**use)
  end

  def setup_default_aws_stubs
    stub_request(:put, 'http://169.254.169.254/latest/api/token')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => /.+/,
          'User-Agent' => /.+/,
          'X-Aws-Ec2-Metadata-Token-Ttl-Seconds' => /.+/

        }
      )
      .to_return(status: 200, body: '', headers: {})

    body = <<~END_BODY
      {
        "Code" : "Success",
        "LastUpdated" : "2012-04-26T16:39:16Z",
        "Type" : "AWS-HMAC",
        "AccessKeyId" : "ASIAIOSFODNN7EXAMPLE",
        "SecretAccessKey" : "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        "Token" : "token",
        "Expiration" : "#{(DateTime.now + 1.hour).iso8601}"
      }
    END_BODY

    stub_request(:get, %r{http://169.254.169.254/latest/meta-data/iam/security-credentials/.*})
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => /.*/,
          'User-Agent' => /.+/
        }
      )
      .to_return(status: 200, body: body, headers: {})
  end

  def setup_webmock_stub(url:, result:, body: nil, method: :post, extras: {}, return_headers: {}, return_status: 200)
    headers =  {
      'Accept' => '*/*',
      'Accept-Encoding' => '',
      'Authorization' => /.+/,
      'Host' => /.+/,
      'User-Agent' => /.+/,
      'X-Amz-Content-Sha256' => /.+/,
      'X-Amz-Date' => /.+/
    }.merge(extras)
    
    # puts url
    # puts headers    

    stub_request(method, url)
      .with(
        body: body,
        headers: headers
      )
      .to_return(status: return_status, body: result, headers: return_headers)
  end

  def requests_responses
    {
      sns_log: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: /\{"logGroupNamePrefix":"sns"\}/,
        result: { 'logGroups' => [
          {
            'arn' => 'arn:aws:logs:us-east-1:\1234567890:log-group:sns/us-east-1/1234567890/DirectPublishToPhoneNumber:*',
            'creationTime' => 1_560_421_537_697,
            'logGroupName' => 'sns/us-east-1/1234567890/DirectPublishToPhoneNumber',
            'metricFilterCount' => 0,
            'retentionInDays' => 30,
            'storedBytes' => 0
          },
          {
            'arn' => 'arn:aws:logs:us-east-1:\1234567890:log-group:sns/us-east-1/1234567890/DirectPublishToPhoneNumber/Failure:*',
            'creationTime' => 1_560_355_721_773,
            'logGroupName' => 'sns/us-east-1/1234567890/DirectPublishToPhoneNumber/Failure',
            'metricFilterCount' => 0,
            'retentionInDays' => 30,
            'storedBytes' => 7032
          }
        ] }
      },
      sns_direct_publish_no_limit: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber"\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"0eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"876543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"3f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"e56694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"84bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"e4342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"de1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"7a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_661_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },
      sns_direct_publish: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","limit":9\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"0eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"876543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"3f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"e56694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"84bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"e4342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"de1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"7a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_661_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },
      sns_direct_publish_page2: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","limit":9,"startTime":\d+\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"0eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"876543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"3f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"e56694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"84bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"e4342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"de1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"7a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_661_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },

      sns_direct_publish_10: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","limit":10\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"0eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"876543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"3f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"e56694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"84bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"e4342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"de1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"7a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_661_497 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846081',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
            '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:48.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_662_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },
      sns_direct_publish_11_empty: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","limit":11\}),
        result: {
          'events' => [],
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 0, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },

      sns_direct_publish_10_failed_empty: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber/Failure","limit":10\}),
        result: {
          'events' => [],
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 0, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },
      sns_direct_publish_10_start_empty: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","limit":10,"startTime":\d+\}),
        result: {
          'events' => [],
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 0, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },

      sns_direct_publish_10_page2: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","nextToken":".+","limit":10\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"9eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"976543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"9f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"956694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"94bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"SUCCESS"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"94342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"9e1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"9a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"9b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_661_497 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846081',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
            '{"notification":{"messageId":"9b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:48.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Delivered","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"SUCCESS"}',
              'timestamp' => 1_646_994_662_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },

      sns_direct_publish_failure_10: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber/Failure","limit":10\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"0eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"FAILURE"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"876543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"FAILURE"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"3f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"FAILURE"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"e56694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"FAILURE"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"84bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"FAILURE"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"e4342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"FAILURE"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"de1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"FAILURE"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"7a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"FAILURE"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"FAILURE"}',
              'timestamp' => 1_646_994_661_497 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846081',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
            '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506873","timestamp":"2022-03-11 10:30:48.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"FAILURE"}',
              'timestamp' => 1_646_994_662_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },

      sns_direct_publish_failure: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber/Failure","limit":9\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"0eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"FAILURE"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"876543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"FAILURE"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"3f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"FAILURE"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"e56694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"FAILURE"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"84bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"FAILURE"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"e4342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"FAILURE"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"de1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"FAILURE"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"7a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"FAILURE"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"FAILURE"}',
              'timestamp' => 1_646_994_661_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },
      sns_direct_publish_failure_page2: {
        url: %r{https://logs.us-east-1.amazonaws.com/},
        body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber/Failure","limit":9,"startTime":\d+\}),
        result: {
          'events' => [
            {
              'eventId' => '36724116826408388857675152699705214080262588937637396480',
              'ingestionTime' => 1_646_766_352_492,
              'logStreamName' => '34f634d5-1ddc-4bdf-8430-8f0f3b3edb8d',
              'message' => '{"notification":{"messageId":"0eb79b44-d9bd-5938-b0cf-c1e572815b74","timestamp":"2022-03-08 19:05:32.271"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":105,"dwellTimeMsUntilDeviceAck":336},"status":"FAILURE"}',
              'timestamp' => 1_646_766_352_401
            },
            { 'eventId' => '36724122115052413434410961624743978129978060131030728704',
              'ingestionTime' => 1_646_766_589_646,
              'logStreamName' => 'ca9c1dea-59ae-46e7-9a0e-b35c13f5bf54',
              'message' =>
              '{"notification":{"messageId":"876543da-df63-5e08-8666-197b7352e60b","timestamp":"2022-03-08 19:09:37.948"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":137,"dwellTimeMsUntilDeviceAck":507},"status":"FAILURE"}',
              'timestamp' => 1_646_766_589_552 },
            { 'eventId' => '36724122185656572732958914494656448639661647835238891520',
              'ingestionTime' => 1_646_766_592_798,
              'logStreamName' => '40a5e72c-ebed-47ef-8eb1-9a0b8bf38ca9',
              'message' =>
              '{"notification":{"messageId":"3f333f14-62c9-5a89-b073-65b5cef847ed","timestamp":"2022-03-08 19:09:37.642"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":136,"dwellTimeMsUntilDeviceAck":427},"status":"FAILURE"}',
              'timestamp' => 1_646_766_592_718 },
            { 'eventId' => '36724122280278634610324348489336479338396136214552510464',
              'ingestionTime' => 1_646_766_597_053,
              'logStreamName' => '76e4808c-c3e3-47af-82bf-a273f8256a3e',
              'message' =>
              '{"notification":{"messageId":"e56694a7-cae5-56b6-884c-ce0666d416f8","timestamp":"2022-03-08 19:09:37.3"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":114,"dwellTimeMsUntilDeviceAck":431},"status":"FAILURE"}',
              'timestamp' => 1_646_766_596_961 },
            { 'eventId' => '36724122294618013772979539170108310761942676651285544960',
              'ingestionTime' => 1_646_766_597_685,
              'logStreamName' => '700b4347-d04d-4d8a-b3ed-cada2e88d941',
              'message' =>
              '{"notification":{"messageId":"84bcaf83-6137-589a-a433-f522cd07a07c","timestamp":"2022-03-08 19:09:36.971"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":116,"dwellTimeMsUntilDeviceAck":358},"status":"FAILURE"}',
              'timestamp' => 1_646_766_597_604 },
            { 'eventId' => '36729201605739951999152780412057416490826735162119749632',
              'ingestionTime' => 1_646_994_361_870,
              'logStreamName' => '4aeed815-d252-42bb-a9b7-c1656f8a222d',
              'message' =>
              '{"notification":{"messageId":"e4342041-71e4-5da4-aba5-7ae45417be04","timestamp":"2022-03-11 10:25:56.086"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":189,"dwellTimeMsUntilDeviceAck":535},"status":"FAILURE"}',
              'timestamp' => 1_646_994_361_792 },
            { 'eventId' => '36729208086626416379732763794509120884183877577620062208',
              'ingestionTime' => 1_646_994_652_485,
              'logStreamName' => 'c8501910-a484-4cf7-91b5-f61efa2ca937',
              'message' =>
              '{"notification":{"messageId":"de1b1329-15ad-55ea-8712-498c32bb5aca","timestamp":"2022-03-11 10:30:46.465"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":127,"dwellTimeMsUntilDeviceAck":330},"status":"FAILURE"}',
              'timestamp' => 1_646_994_652_405 },
            { 'eventId' => '36729208201898968310937554819410646836629166881415954432',
              'ingestionTime' => 1_646_994_657_699,
              'logStreamName' => '77cb0857-4c3e-4189-aa3a-71218c60594c',
              'message' =>
              '{"notification":{"messageId":"7a4b605c-6771-5dcb-af8a-3af94067166c","timestamp":"2022-03-11 10:30:46.804"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":117,"dwellTimeMsUntilDeviceAck":497},"status":"FAILURE"}',
              'timestamp' => 1_646_994_657_574 },
            { 'eventId' => '36729208289384791724773189408359330032291169384572846080',
              'ingestionTime' => 1_646_994_661_590,
              'logStreamName' => '3afbd208-2fe3-45ac-a980-12169ff7be23',
              'message' =>
              '{"notification":{"messageId":"8b874c13-ba47-5ee3-8972-16b69d506863","timestamp":"2022-03-11 10:30:47.479"},"delivery":{"numberOfMessageParts":1,"destination":"+16175550118","priceInUSD":0.00831,"smsType":"Transactional","providerResponse":"Message body is invalid","dwellTimeMs":140,"dwellTimeMsUntilDeviceAck":318},"status":"FAILURE"}',
              'timestamp' => 1_646_994_661_497 }
          ],
          'nextToken' => 'Bxkq6kVGFtq2y_MoigeqscPOdhXVbhiVtLoAmXb5jCqONfU_4YjUoyhkuJqXmoWMbYtzZNt13ZcunC0qLRM6VLELP0V2oiad4AgVXqksKt3CWElLLlF8GalQzVYWY47q0ZRC2Z-k5c41C1_atG8cG1ouimR6OxGWyyzsyMbfY3ZtLyAM21k1tPfHd1IjyOphvY4KnZJhHXyxvAVzyKkFM7fcVsQAj6m8--rZwoqFPTU5sG-d083tXlnO87fMkeF9ocNhRfA2DDHThj-DO06FtA',
          'searchStatistics' => { 'approximateTotalLogStreamCount' => 36, 'completedLogStreamCount' => 0 },
          'searchedLogStreams' => []
        }
      },
      pinpoint_validate: {
        url: %r{https://pinpoint.us-east-1.amazonaws.com/v1/phone/number/validate},
        body: /\{"PhoneNumber":"\+1\d+"\}/,

        result: { 'CountryCodeIso2' => 'US',
                  'CountryCodeNumeric' => '1',
                  'Country' => 'United States',
                  'City' => 'Massapequa',
                  'ZipCode' => '11758',
                  'Timezone' => 'America/New_York',
                  'CleansedPhoneNumberNational' => '5162621289',
                  'CleansedPhoneNumberE164' => '+15162621289',
                  'Carrier' => 'T-Mobile USA, Inc.',
                  'PhoneTypeCode' => 0,
                  'PhoneType' => 'MOBILE',
                  'OriginalPhoneNumber' => '+15162621289' }
      },
      sns_opt_out: {
        url: %r{https://sns.us-east-1.amazonaws.com/},
        body: 'Action=ListPhoneNumbersOptedOut&Version=2010-03-31',

        result: <<~END_RES
          <ListPhoneNumbersOptedOutResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">
            <ListPhoneNumbersOptedOutResult>
              <nextToken>ayJPcmlnaW5hdGlvbkVudGl0eSI6eyJzIjoiYXJuOmF3czppYW06Ojc1NjU5ODI0ODIzNDpyb290In0sIkRlc3RpbmF0aW9uUGhvbmVOdW1iZXIiOnsicyI6IisxMjc2MzkzMTU2NSJ9fQ==</nextToken>
              <phoneNumbers>
                <member>+16171112222</member>
                <member>+16171112223</member>
                <member>+16171112224</member>
                <member>+16171112225</member>
                <member>+16171112226</member>
              </phoneNumbers>
            </ListPhoneNumbersOptedOutResult>
            <ResponseMetadata>
              <RequestId>d4fabe74-73a0-5878-8226-e4c072b96252</RequestId>
            </ResponseMetadata>
          </ListPhoneNumbersOptedOutResponse>
        END_RES

      },
      sns_opt_out_page2: {
        url: %r{https://sns.us-east-1.amazonaws.com/},
        body: /Action=ListPhoneNumbersOptedOut&Version=2010-03-31&nextToken=.+/,

        result: <<~END_RES
          <ListPhoneNumbersOptedOutResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">
            <ListPhoneNumbersOptedOutResult>
              <nextToken>ayJPcmlnaW5hdGlvbkVudGl0eSI6eyJzIjoiYXJuOmF3czppYW06Ojc1NjU5ODI0ODIzNDpyb290In0sIkRlc3RpbmF0aW9uUGhvbmVOdW1iZXIiOnsicyI6IisxMjc2MzkzMTU2NSJ9fQ==</nextToken>
              <phoneNumbers>
                <member>+16171112222</member>
                <member>+16171112223</member>
                <member>+16171112224</member>
                <member>+16171112225</member>
                <member>+16171112226</member>
              </phoneNumbers>
            </ListPhoneNumbersOptedOutResult>
            <ResponseMetadata>
              <RequestId>d4fabe74-73a0-5878-8226-e4c072b96252</RequestId>
            </ResponseMetadata>
          </ListPhoneNumbersOptedOutResponse>
        END_RES

      },
      sns_send_sms: {
        url: %r{https://sns.us-east-1.amazonaws.com/},
        body: /Action=Publish&Message=.+&MessageAttributes.entry.1.Name=AWS.SNS.SMS.SenderID&MessageAttributes.entry.1.Value.DataType=String&MessageAttributes.entry.1.Value.StringValue=.+&MessageAttributes.entry.2.Name=AWS.SNS.SMS.SMSType&MessageAttributes.entry.2.Value.DataType=String&MessageAttributes.entry.2.Value.StringValue=.+&PhoneNumber=%2B\d+&Version=2010-03-31/,

        result: <<~END_RES
          <PublishResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">
            <PublishResult>
              <MessageId>a0841ada-1649-547f-9bc7-406f166db83c</MessageId>
            </PublishResult>
            <ResponseMetadata>
              <RequestId>9fd827cd-f875-5cd0-9714-7d78f8517093</RequestId>
            </ResponseMetadata>
          </PublishResponse>
        END_RES
      },
      s3_shortlink: {
        url: %r{https://s3.amazonaws.com/test-shortlink.fphs.link/.+},
        result: '',
        method: :put,
        body: /.*/,
        return_headers: {
          'X-Amz-Id-2' => 'c3jSX0n6h19AANv8wlMRV/uB/AR366QKlfSlRYvtOwcAAYADTpU82UDZopdFgOpbLjI11LFs8qA=',
          'X-Amz-Request-Id' => 'ENRKHQ3FJTHYCRR6',
          'Date' => 'Wed, 23 Mar 2022 17:00:30 GMT',
          'Last-Modified' => 'Wed, 23 Mar 2022 17:00:29 GMT',
          'Etag' => '"cfcb78814dc1ce18a2220b926a3112cc"',
          'X-Amz-Meta-Content-Type' => 'text/html',
          'Accept-Ranges' => 'bytes',
          'Content-Type' => 'binary/octet-stream',
          'Server' => 'AmazonS3'
          # 'Content-Length' => '450'
        }
      },
      s3_head_shortlink: {
        url: %r{https://s3.amazonaws.com/test-shortlink.fphs.link/.+},
        result: '',
        method: :head,
        return_headers: {
          'X-Amz-Request-Id' => '03C8Z2DJKB2C0F8J',
          'X-Amz-Id-2' => 'sim74pQVNqYHPNDUirbEz2FF5taziqK2WxtSvlOVHi+K6alwRyfJ1KK+VCxhxIgDaEQhi8MpZUo=',
          'Content-Type' => 'application/xml',
          'Date' => 'Wed, 23 Mar 2022 17:09:22 GMT',
          'Server' => 'AmazonS3',
          'Etag' => '"cfcb78814dc1ce18a2220b926a3112cc"'
        }
      },
      s3_get_access_list: {
        url: %r{https://test-fphs-url-shortener-logs.s3.amazonaws.com/\?list-type=2&prefix=access/&start-after=access/.+},
        method: :get,
        result: <<~END_RES
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>test-fphs-url-shortener-logs</Name><Prefix>access/</Prefix><StartAfter>access/2022-03-23</StartAfter><KeyCount>1</KeyCount><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>access/2022-03-23-07-43-19-1A1919044CEA2BF1</Key><LastModified>2022-03-23T07:43:20.000Z</LastModified><ETag>&quot;b6171500b515d53ab0cb879bc046f176&quot;</ETag><Size>3495</Size><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>#{'        '}
        END_RES
      },
      s3_get_access_item: {
        url: %r{https://test-fphs-url-shortener-logs.s3.amazonaws.com/access/.+},
        method: :get,

        result: <<~END_RES
          9e134f3964d1864709f668f9d3e8db57ca701a10a74bb930fb6f6c31d0ebf450 test-shortlink.fphs.link [23/Mar/2022:06:18:49 +0000] 3.83.64.224 arn:aws:sts::756598248234:assumed-role/AWSServiceRoleForAccessAnalyzer/access-analyzer BCW1ZG6PEJ685NRK REST.GET.POLICY_STATUS - "GET /test-shortlink.fphs.link?policyStatus HTTP/1.1" 200 - 141 - 5 - "-" "aws-sdk-java/2.17.124 Linux/4.14.252-207.481.amzn2.x86_64 OpenJDK_64-Bit_Server_VM/25.322-b06 Java/1.8.0_322 vendor/Amazon.com_Inc. md/internal exec-env/AWS_Lambda_java8.al2 io/sync http/Apache cfg/retry-mode/legacy" - lNT2bcaGer4lstGJ1/sya8p+fEnQF+OUojcuu5GchWCW37ZHBc3CcQ9TRWTtOTPJ7RaYivkCLc4= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader s3.amazonaws.com TLSv1.2 -
          9e134f3964d1864709f668f9d3e8db57ca701a10a74bb930fb6f6c31d0ebf450 test-shortlink.fphs.link [23/Mar/2022:06:18:49 +0000] 3.83.64.224 arn:aws:sts::756598248234:assumed-role/AWSServiceRoleForAccessAnalyzer/access-analyzer BCWAJSV203FH1HRY REST.GET.BUCKETPOLICY - "GET /test-shortlink.fphs.link?policy HTTP/1.1" 200 - 178 - 10 - "-" "aws-sdk-java/2.17.124 Linux/4.14.252-207.481.amzn2.x86_64 OpenJDK_64-Bit_Server_VM/25.322-b06 Java/1.8.0_322 vendor/Amazon.com_Inc. md/internal exec-env/AWS_Lambda_java8.al2 io/sync http/Apache cfg/retry-mode/legacy" - qF7yZKUOLc6AdLDAUnm8USeODptFpLdjxUSLrV3Exw1KFgNMwEyDZ3LRKy/FubF0frLTj/q3Bio= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader s3.amazonaws.com TLSv1.2 -
          9e134f3964d1864709f668f9d3e8db57ca701a10a74bb930fb6f6c31d0ebf450 test-shortlink.fphs.link [23/Mar/2022:06:18:49 +0000] 3.83.64.224 arn:aws:sts::756598248234:assumed-role/AWSServiceRoleForAccessAnalyzer/access-analyzer BCWCCQ54YEB2V19T REST.GET.LOCATION - "GET /test-shortlink.fphs.link?location HTTP/1.1" 200 - 108 - 14 - "-" "aws-sdk-java/2.17.124 Linux/4.14.252-207.481.amzn2.x86_64 OpenJDK_64-Bit_Server_VM/25.322-b06 Java/1.8.0_322 vendor/Amazon.com_Inc. md/internal exec-env/AWS_Lambda_java8.al2 io/sync http/Apache cfg/retry-mode/legacy" - CmmOE0FvFel99t8TvW7A2/G6jhnlRf94vVGIlTSd/eX9LKWQ8XYxEOw5F/E9t/PzLQmNjHpSDYM= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader s3.amazonaws.com TLSv1.2 -
          9e134f3964d1864709f668f9d3e8db57ca701a10a74bb930fb6f6c31d0ebf450 test-shortlink.fphs.link [23/Mar/2022:06:18:49 +0000] 3.83.64.224 arn:aws:sts::756598248234:assumed-role/AWSServiceRoleForAccessAnalyzer/access-analyzer BCWDG2TTT0YBW4BZ REST.GET.ACL - "GET /test-shortlink.fphs.link?acl HTTP/1.1" 200 - 1449 - 11 - "-" "aws-sdk-java/2.17.124 Linux/4.14.252-207.481.amzn2.x86_64 OpenJDK_64-Bit_Server_VM/25.322-b06 Java/1.8.0_322 vendor/Amazon.com_Inc. md/internal exec-env/AWS_Lambda_java8.al2 io/sync http/Apache cfg/retry-mode/legacy" - aPxTOk/Gopafb7HgsQbzPWsb/TUsivyWiRgzOeAWUnBSOpzgcC+8r8BXG5QfPpkVKNaQ4HO77mQ= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader s3.amazonaws.com TLSv1.2 -
          9e134f3964d1864709f668f9d3e8db57ca701a10a74bb930fb6f6c31d0ebf450 test-shortlink.fphs.link [23/Mar/2022:06:18:49 +0000] 3.83.64.224 arn:aws:sts::756598248234:assumed-role/AWSServiceRoleForAccessAnalyzer/access-analyzer BCWF726WAKAAXB1Q REST.GET.PUBLIC_ACCESS_BLOCK - "GET /test-shortlink.fphs.link?publicAccessBlock HTTP/1.1" 200 - 328 - 7 - "-" "aws-sdk-java/2.17.124 Linux/4.14.252-207.481.amzn2.x86_64 OpenJDK_64-Bit_Server_VM/25.322-b06 Java/1.8.0_322 vendor/Amazon.com_Inc. md/internal exec-env/AWS_Lambda_java8.al2 io/sync http/Apache cfg/retry-mode/legacy" - QwZMHQZy1WHJPLJBHeSLd9LXkWLWGtalj23hV2Q5REXl57tV1i6Qu7jR75tFBP2iWAO4pm3NLpw= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader s3.amazonaws.com TLSv1.2 -#{'      '}
        END_RES
      }
    }
  end
end
