# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Formatter::TagFormatter, type: :model do
  include UserSupport

  # @param [Array] tests - [[operation, value, expected result, (optional alternative user)],...]
  def run(tests)
    tests.each do |test|
      res = Formatter::TagFormatter.format_with test[0].to_s, test[1], test[1], test[3] || @user, test[4], test[5]
      expect(res).to eq(test[2]), "Test: #{test[0]} '#{res}' expected to be '#{test[2]}'"
    end
  end

  before :example do
    @ldn_user, = create_user
    @ldn_user.current_admin = @admin
    @ldn_user.user_preference.update!(date_format: 'dd/mm/yyyy', date_time_format: 'dd/mm/yyyy hh:mm am/pm', timezone: 'London')

    @ldn_user24, = create_user
    @ldn_user24.current_admin = @admin
    @ldn_user24.user_preference.update!(date_format: 'dd/mm/yyyy', date_time_format: 'dd/mm/yyyy 24h:mm', time_format: '24h:mm', timezone: 'London')

    create_user
  end

  it 'substitutes with simple formats' do
    basic_string = 'this is  a String!'

    tests = [
      [:capitalize, basic_string, 'This is  a string!'],
      [:titleize, basic_string, 'This Is  A String!'],
      [:uppercase, basic_string, 'THIS IS  A STRING!'],
      [:lowercase, basic_string, 'this is  a string!'],
      [:underscore, basic_string, 'this is  a string!'],
      [:underscore, 'ThisIsAString', 'this_is_a_string'],
      [:hyphenate, basic_string, 'this-is--a-String!'],
      [:id_hyphenate, basic_string, 'this-is--a-string-'],
      [:id_underscore, basic_string, 'this_is__a_string_'],
      [:initial, basic_string, 'T'],
      [:first, basic_string, 't'],
      [:last, basic_string, '!']
    ]

    run tests
  end

  it 'substitutes dates and times' do
    date = Date.parse('2001-10-09')
    date_time = DateTime.parse('1989-12-10T13:43:01Z')
    date_time_early = DateTime.parse('1989-12-10T02:43:01Z')
    date_time_est = DateTime.parse('1989-12-10 13:43:01-04:00')
    date_time_est_summer = DateTime.parse('1989-06-10 13:43:01-04:00')
    time_without_zone = Time.parse('2000-01-01T10:35Z')

    tests = [
      [:age, Date.today - 10.years, 10],
      [:age, Date.today - 10.years - 1.day, 10],
      [:age, Date.today - 10.years - 364.days, 10],
      [:age, Date.today - 10.years + 1.day, 9],
      [:date, date, '10/09/2001'],
      [:date, date, '09/10/2001', @ldn_user],
      [:date_time, date_time, '12/10/1989 1:43 pm'],
      [:date_time, date_time, '10/12/1989 1:43 pm', @ldn_user],
      [:date_time, date_time, '10/12/1989 13:43', @ldn_user24],
      [:date_time, date_time_early, '12/10/1989 2:43 am'],
      [:date_time, date_time_est, '10/12/1989 13:43', @ldn_user24],
      [:time, date_time, '8:43 am'],
      [:time, date_time, '1:43 pm', @ldn_user],
      [:time, date_time, '13:43', @ldn_user24],
      [:time, date_time_est, '12:43 pm'],
      [:time, date_time_est, '5:43 pm', @ldn_user],
      [:time, date_time_est_summer, '1:43 pm'],
      [:time, date_time_est_summer, '6:43 pm', @ldn_user],
      [:time_with_zone, date_time, '8:43 am'],
      [:time_with_zone, date_time, '1:43 pm', @ldn_user],
      [:time_show_zone, date_time, '8:43 am Eastern Time (US & Canada)'],
      [:time_show_zone, date_time, '1:43 pm London', @ldn_user],
      [:time_show_zone, date_time_est, '12:43 pm Eastern Time (US & Canada)'],
      [:time_show_zone, date_time_est, '5:43 pm London', @ldn_user],
      [:time_show_zone, date_time_est_summer, '1:43 pm Eastern Time (US & Canada)'],
      [:time_show_zone, date_time_est_summer, '6:43 pm London', @ldn_user],
      [:time_sec, date_time, '8:43:01 am'],
      [:time_sec, date_time, '1:43:01 pm', @ldn_user],
      [:time_sec, date_time, '13:43:01', @ldn_user24],
      [:time_ignore_zone, time_without_zone, '10:35 am'],
      [:time_ignore_zone, time_without_zone, '10:35 am', @ldn_user],
      [:time_ignore_zone, time_without_zone, '10:35', @ldn_user24],
      [:dicom_datetime, date_time, '19891210134301+0000'],
      [:dicom_date, date, '20011009'],
      [:redcap_date, date, '2001-10-09'],
      [:iso8601_datetime, date_time, '1989-12-10T13:43:01+00:00'],
      [:date_time_with_zone, date_time, '12/10/1989 1:43 pm'],
      [:date_time_with_zone, date_time, '10/12/1989 1:43 pm', @ldn_user],
      [:date_time_with_zone, date_time_early, '12/10/1989 2:43 am'],
      [:date_time_with_zone, date_time_early, '10/12/1989 2:43 am', @ldn_user],
      [:date_time_with_zone, date_time_est, '12/10/1989 1:43 pm'],
      [:date_time_with_zone, date_time_est, '10/12/1989 1:43 pm', @ldn_user],
      [:date_time_show_zone, date_time, '12/10/1989 8:43 am Eastern Time (US & Canada)'],
      [:date_time_show_zone, date_time, '10/12/1989 1:43 pm London', @ldn_user],
      [:date_time_show_zone, date_time_early, '12/09/1989 9:43 pm Eastern Time (US & Canada)'],
      [:date_time_show_zone, date_time_early, '10/12/1989 2:43 am London', @ldn_user]
    ]

    run tests
  end

  it 'handles arrays' do
    array = [1, 'test, this', '', 'like it', nil, 'and', 99]
    tests = [
      [:join_with_space, array, '1 test, this  like it  and 99'],
      [:join_with_comma, array, '1, test, this, , like it, , and, 99'],
      [:join_with_csv, array, '1,"test, this","",like it,,and,99'],
      [:join_with_semicolon, array, '1; test, this; ; like it; ; and; 99'],
      [:join_with_pipe, array, '1|test, this||like it||and|99'],
      [:join_with_dot, array, '1.test, this..like it..and.99'],
      [:join_with_at, ['phil.ayres', 'test.tst'], 'phil.ayres@test.tst'],
      [:join_with_slash, ['abc', 'def'], 'abc/def'],
      [:join_with_newline, array, "1\ntest, this\n\nlike it\n\nand\n99"],
      [:join_with_2newlines, array, "1\n\ntest, this\n\n\n\nlike it\n\n\n\nand\n\n99"],
      [:compact, array, [1, 'test, this', 'like it', 'and', 99]],
      [:sort, ['bce', 'a', 'some', '123'], ['123', 'a', 'bce', 'some']],
      [:sort_reverse, [99, 100, 101, 22], [101, 100, 99, 22]],
      [:uniq, ['bce', 'a', 'some', 'a', 'some', '123'], ['bce', 'a', 'some', '123']],
      [:markdown_list, array, "- 1\n- test, this\n- \n- like it\n- \n- and\n- 99"],
      [:html_list, array, "<ul><li>1</li>\n  <li>test, this</li>\n  <li></li>\n  <li>like it</li>\n  <li></li>\n  <li>and</li>\n  <li>99</li></ul>"]
    ]

    run tests
  end

  it 'handles strings' do
    string = ' abh jkj fff 9 '
    tests = [
      [:plaintext, "1\ntest, this\n\nlike it\n\nand\n99", '1<br>test, this<br><br>like it<br><br>and<br>99'],
      [:strip, string, 'abh jkj fff 9'],
      [:split_space, 'hello world test', ['hello', 'world', 'test']],
      [:split_lines, "1\ntest, this\n\nlike it\n\nand", ['1', 'test, this', '', 'like it', '', 'and']],
      [:split_comma, ' abh,jkj,fff,9 ', [' abh', 'jkj', 'fff', '9 ']],
      [:split_csv, '" abh","jkj","fff,ggg",9,""', [' abh', 'jkj', 'fff,ggg', '9', '']],
      [:split_semicolon, ' abh;jkj;fff;9 ', [' abh', 'jkj', 'fff', '9 ']],
      [:split_pipe, ' abh|jkj|fff|9 ', [' abh', 'jkj', 'fff', '9 ']],
      [:split_dot, ' abh.jkj.fff.9 ', [' abh', 'jkj', 'fff', '9 ']],
      [:split_at, 'phil.ayres@test.tst', ['phil.ayres', 'test.tst']],
      [:split_slash, 'abc/def', ['abc', 'def']],
      [:markup, "# Hello!\n\nHere is some text", "<h1 id=\"hello\">Hello!</h1>\n\n<p>Here is some text</p>\n"]
    ]

    run tests
  end

  it 'handles pass-through and utility formatters' do
    tests = [
      [:no_html_tag, 'test value', 'test value'],
      [:no_html_tag, '<p>HTML content</p>', '<p>HTML content</p>'],
      [:ignore_missing, nil, ''],
      [:ignore_missing, 'present', 'present']
    ]

    run tests
  end

  it 'handles hash data' do
    data = { 'completeyn' => 'y',
             'grant' => [
               { 'grantid' => 'r01 hl060133', 'acronym' => 'hl', 'agency' => 'nhlbi nih hhs', 'country' => 'united states' },
               { 'grantid' => 'r01 hl105239', 'acronym' => 'hl', 'agency' => 'nhlbi nih hhs', 'country' => 'united states' },
               { 'grantid' => 'r01-hl-60133-01', 'acronym' => 'hl', 'agency' => 'nhlbi nih hhs', 'country' => 'united states' }
             ] }
    tests = [
      [:json, data, <<~END_JSON
        {
          "completeyn": "y",
          "grant": [
            {
              "grantid": "r01 hl060133",
              "acronym": "hl",
              "agency": "nhlbi nih hhs",
              "country": "united states"
            },
            {
              "grantid": "r01 hl105239",
              "acronym": "hl",
              "agency": "nhlbi nih hhs",
              "country": "united states"
            },
            {
              "grantid": "r01-hl-60133-01",
              "acronym": "hl",
              "agency": "nhlbi nih hhs",
              "country": "united states"
            }
          ]
        }
      END_JSON
        .strip],
      [:yaml, data, <<~END_YAML
        completeyn: "y"
        grant:
        - grantid: r01 hl060133
          acronym: hl
          agency: nhlbi nih hhs
          country: united states
        - grantid: r01 hl105239
          acronym: hl
          agency: nhlbi nih hhs
          country: united states
        - grantid: r01-hl-60133-01
          acronym: hl
          agency: nhlbi nih hhs
          country: united states
      END_YAML
      ]
    ]

    run tests
  end

  it 'handles gets general selection labels' do
    # Ensure the general selection records have distinct name (label) and value
    # so label lookups return the human-readable name, not the raw value
    %w[player_contacts_source player_infos_source].each do |item_type|
      gs = Classification::GeneralSelection.find_by(item_type: item_type, value: 'nflpa2')
      gs&.update_column(:name, 'NFLPA 2')
    end

    pi = PlayerContact.new(
      data: 'sakdjfhkj@askjdhkdjh.tst',
      rec_type: 'email',
      rank: 10,
      source: 'nflpa2'
    )

    tests = [
      [:general_selection_label, '10', 'primary', nil, 'rank', pi],
      [:general_selection_label, 'nflpa2', 'NFLPA 2', nil, 'source', pi],
      [:general_selection_label, 'email', 'Email', nil, 'rec_type', pi]
    ]

    run tests

    pi = PlayerInfo.new(
      last_name: 'test',
      rank: 10,
      source: 'nflpa2'
    )

    tests = [
      [:general_selection_label, 'nflpa2', 'NFLPA 2', nil, 'source', pi]
    ]

    run tests
  end

  it 'handles string manipulation and conversion' do
    html_string = '<p>Hello <strong>World</strong></p>\nSecond line'
    markdown_string = "# Title\n\nThis is **bold** text."

    tests = [
      [:strip, '  spaced text  ', 'spaced text'],
      [:plaintext, html_string, '<p>Hello <strong>World</strong></p>\\nSecond line'],
      [:markup, markdown_string, "<h1 id=\"title\">Title</h1>\n\n<p>This is <strong>bold</strong> text.</p>\n"],
      [:ignore_missing, nil, ''],
      [:ignore_missing, 'present', 'present']
    ]

    run tests
  end

  it 'handles data format conversion' do
    data_hash = { 'key1' => 'value1', 'key2' => ['item1', 'item2'] }
    data_array = ['item1', 'item2', 'item3']

    yaml_expected = "key1: value1\nkey2:\n- item1\n- item2\n"

    json_expected = <<~JSON.strip
      {
        "key1": "value1",
        "key2": [
          "item1",
          "item2"
        ]
      }
    JSON

    tests = [
      [:yaml, data_hash, yaml_expected],
      [:json, data_hash, json_expected],
      [:yaml, data_array, "- item1\n- item2\n- item3\n"],
      [:json, data_array, "[\n  \"item1\",\n  \"item2\",\n  \"item3\"\n]"]
    ]

    run tests
  end

  it 'parses JSON and YAML strings into objects' do
    json_string = '{"key1":"value1","key2":["item1","item2"]}'
    yaml_string = "key1: value1\nkey2:\n- item1\n- item2\n"
    expected_hash = { 'key1' => 'value1', 'key2' => %w[item1 item2] }

    tests = [
      [:parse_json, json_string, expected_hash],
      [:parse_yaml, yaml_string, expected_hash]
    ]

    run tests
  end

  it 'chains parse_json and parse_yaml with serialization formatters' do
    json_string = '{"key1":"value1","key2":["item1","item2"]}'
    yaml_string = "key1: value1\nkey2:\n- item1\n- item2\n"

    # parse_json then serialize as yaml
    parsed = Formatter::TagFormatter.format_with 'parse_json', json_string, json_string
    yaml_result = Formatter::TagFormatter.format_with 'yaml', parsed, parsed
    expect(yaml_result).to eq "key1: value1\nkey2:\n- item1\n- item2\n"

    # parse_yaml then serialize as json
    parsed = Formatter::TagFormatter.format_with 'parse_yaml', yaml_string, yaml_string
    json_result = Formatter::TagFormatter.format_with 'json', parsed, parsed
    expect(json_result).to eq "{\n  \"key1\": \"value1\",\n  \"key2\": [\n    \"item1\",\n    \"item2\"\n  ]\n}"
  end

  it 'returns nil for invalid JSON and YAML in parse operations' do
    tests = [
      [:parse_json, 'not valid json {{{', nil],
      [:parse_yaml, "key: [\ninvalid", nil]
    ]

    run tests
  end

  it 'handles numeric indexing for strings and arrays' do
    test_string = 'Hello World'
    test_array = ['first', 'second', 'third', 'fourth']

    # The numeric indexing is processed by the process method
    # For strings: operation.to_i != 0 → curr_val[0..operation.to_i]
    # For arrays: operation.to_i.to_s == operation → curr_val[operation.to_i]

    tests = [
      [0, test_array, 'first'],         # First element of array (0 as string matches to_i.to_s)
      [2, test_array, 'third'],         # Third element of array
      [10, test_array, nil],            # Beyond array bounds
      [1, test_string, 'He'],           # First 2 characters from string (0..1)
      [4, test_string, 'Hello']         # First 5 characters from string (0..4)
    ]

    run tests
  end

  it 'handles specialized date time formats with edge cases' do
    utc_datetime = DateTime.parse('2023-03-15T14:30:45Z')
    date_only = Date.parse('2023-03-15')

    tests = [
      [:dicom_datetime, utc_datetime, '20230315143045+0000'],
      [:dicom_date, date_only, '20230315'],
      [:dicom_date, utc_datetime, '20230315'],
      [:redcap_date, date_only, '2023-03-15'],
      [:redcap_date, utc_datetime, '2023-03-15'],
      [:iso8601_datetime, utc_datetime, '2023-03-15T14:30:45+00:00'],
      [:dicom_datetime, 'not a date', nil],
      [:dicom_date, 'not a date', nil],
      [:redcap_date, 'not a date', nil]
    ]

    run tests
  end

  it 'handles timezone edge cases' do
    # Test daylight saving time transitions
    winter_datetime = DateTime.parse('2023-01-15T18:30:00Z')  # UTC winter
    summer_datetime = DateTime.parse('2023-07-15T18:30:00Z')  # UTC summer

    tests = [
      [:date_time_show_zone, winter_datetime, '01/15/2023 1:30 pm Eastern Time (US & Canada)'],
      [:date_time_show_zone, summer_datetime, '07/15/2023 2:30 pm Eastern Time (US & Canada)'],
      [:date_time_show_zone, winter_datetime, '15/01/2023 6:30 pm London', @ldn_user],
      [:date_time_show_zone, summer_datetime, '15/07/2023 7:30 pm London', @ldn_user]
    ]

    run tests
  end
end
