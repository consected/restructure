# frozen_string_literal: true

module BulkMsg
  module AwsApiStubs
    def setup_stub(type, result: nil)
      use = requests_responses[type]
      use[result: result] if result
      use[:result] = use[:result].to_json if use[:result].is_a? Hash

      setup_webmock_stub(**use)
    end

    def setup_webmock_stub(url:, body:, result:)
      stub_request(:post, "https://#{url}/")
        .with(
          body: body,
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => '',
            'Authorization' => /.+/,
            'Content-Length' => /.+/,
            'Content-Type' => /.+/,
            'Host' => url,
            'User-Agent' => /.+/,
            'X-Amz-Content-Sha256' => /.+/,
            'X-Amz-Date' => /.+/,
            'X-Amz-Security-Token' => /.+/,
            'X-Amz-Target' => /.+/
          }
        )
        .to_return(status: 200, body: result, headers: {})
    end

    def requests_responses
      {
        sns_log: {
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
          body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","limit":11\}),
          result: {
            'events' => [],
            'searchStatistics' => { 'approximateTotalLogStreamCount' => 0, 'completedLogStreamCount' => 0 },
            'searchedLogStreams' => []
          }
        },

        sns_direct_publish_10_failed_empty: {
          url: 'logs.us-east-1.amazonaws.com',
          body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber/Failure","limit":10\}),
          result: {
            'events' => [],
            'searchStatistics' => { 'approximateTotalLogStreamCount' => 0, 'completedLogStreamCount' => 0 },
            'searchedLogStreams' => []
          }
        },
        sns_direct_publish_10_start_empty: {
          url: 'logs.us-east-1.amazonaws.com',
          body: %r(\{"logGroupName":"sns/us-east-1/\d+/DirectPublishToPhoneNumber","limit":10,"startTime":\d+\}),
          result: {
            'events' => [],
            'searchStatistics' => { 'approximateTotalLogStreamCount' => 0, 'completedLogStreamCount' => 0 },
            'searchedLogStreams' => []
          }
        },

        sns_direct_publish_10_page2: {
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
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
          url: 'logs.us-east-1.amazonaws.com',
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
        }
      }
    end
  end
end
