# frozen_string_literal: true

require 'rails_helper'

# Debugging specs for UI performance issues
# These tests inject JavaScript to monitor for constant DOM mutations, event firing,
# or other issues that could cause browser extensions like Bitwarden to trigger constantly.
#
# Issue: UI lock-up when clicking between report search tabs
# Suspected cause: Constant DOM mutations or events that trigger password manager plugins
#
# FINDINGS FROM ANALYSIS:
# =======================
# 1. Activity settles quickly after tab click (within ~1 second)
# 2. No continuous polling or infinite loops detected
# 3. No duplicate event handlers accumulating
# 4. Main source of mutations: Bootstrap tooltip/popover initialization on .add-icon elements
#    - setup_bootstrap_items runs with 600ms setTimeout and adds 'attached_bs' class
#    - This causes ~26 class attribute mutations per tab switch
# 5. ARIA attribute changes happen on all collapse panels due to Bootstrap's accordion behavior
#
# POTENTIAL OPTIMIZATIONS:
# - Batch DOM mutations using DocumentFragment or requestAnimationFrame
# - Initialize Bootstrap tooltips/popovers only on first interaction (lazy init)
# - Consider using CSS :hover for simple tooltips instead of JS popovers
#
# This spec is designed to identify:
# 1. Constant DOM mutations (via MutationObserver)
# 2. Event handlers firing repeatedly
# 3. Timer/interval activity that's too frequent
# 4. Cascading event triggers
describe 'UI performance debugging', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include ReportSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    SetupHelper.feature_setup

    seed_database
    create_data_set_outside_tx

    @admin, @admin_password = create_admin
    @user, @good_password = create_user
    @good_email = @user.email

    # Grant view_reports access
    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id,
      access: :read,
      resource_type: :general,
      resource_name: :view_reports,
      current_admin: @admin,
      user: @user
    )

    # Create searchable reports for testing
    @reports = []
    @test_suffix = SecureRandom.hex(4)
    3.times do |i|
      @reports << create_searchable_report("Debug Test Report #{i + 1} #{@test_suffix}")
    end
  end

  def create_searchable_report(name)
    sql = "select id as master_id from masters where id::text like '%' || :search_text || '%' limit 10"
    search_attrs = <<~END_CONFIG
      search_text:
        text:
          all: true
          multiple: single
          disabled: false
    END_CONFIG
    report = Report.create!(
      current_admin: @admin,
      name: name,
      description: "Test searchable report: #{name}",
      sql: sql,
      search_attrs: search_attrs,
      disabled: false,
      report_type: 'search',
      auto: false,
      searchable: true,
      position: rand(1..100)
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: report.alt_resource_name,
      current_admin: @admin
    )

    report
  end

  before :each do
    validate_setup
  end

  # Helper to inject the DOM mutation monitor
  def inject_dom_mutation_monitor
    page.execute_script(<<~JS)
      window._debug = window._debug || {};
      window._debug.mutationLog = [];
      window._debug.mutationCount = 0;
      window._debug.mutationsBySecond = {};
      window._debug.startTime = Date.now();

      // Track mutations by type
      window._debug.mutationTypes = {
        childList: 0,
        attributes: 0,
        characterData: 0
      };

      // Track frequently mutated elements
      window._debug.elementMutations = {};

      window._debug.mutationObserver = new MutationObserver(function(mutations) {
        var now = Date.now();
        var secondKey = Math.floor((now - window._debug.startTime) / 1000);

        mutations.forEach(function(mutation) {
          window._debug.mutationCount++;
          window._debug.mutationTypes[mutation.type]++;

          // Track which second this mutation happened
          window._debug.mutationsBySecond[secondKey] = (window._debug.mutationsBySecond[secondKey] || 0) + 1;

          // Track which elements are mutating most
          var targetId = '';
          if (mutation.target.id) {
            targetId = '#' + mutation.target.id;
          } else if (mutation.target.className && typeof mutation.target.className === 'string') {
            targetId = '.' + mutation.target.className.split(' ')[0];
          } else if (mutation.target.tagName) {
            targetId = mutation.target.tagName.toLowerCase();
          } else {
            targetId = 'text-node';
          }

          window._debug.elementMutations[targetId] = (window._debug.elementMutations[targetId] || 0) + 1;

          // Log significant mutations (limit to avoid memory issues)
          if (window._debug.mutationLog.length < 500) {
            window._debug.mutationLog.push({
              time: now - window._debug.startTime,
              type: mutation.type,
              target: targetId,
              attributeName: mutation.attributeName || null,
              addedNodes: mutation.addedNodes ? mutation.addedNodes.length : 0,
              removedNodes: mutation.removedNodes ? mutation.removedNodes.length : 0
            });
          }
        });
      });

      window._debug.mutationObserver.observe(document.body, {
        childList: true,
        attributes: true,
        characterData: true,
        subtree: true,
        attributeOldValue: true
      });

      console.log('[DEBUG] DOM mutation observer started');
    JS
  end

  # Helper to inject event firing monitor
  def inject_event_monitor
    page.execute_script(<<~JS)
      window._debug = window._debug || {};
      window._debug.eventLog = [];
      window._debug.eventCounts = {};
      window._debug.eventsBySecond = {};
      window._debug.startTime = window._debug.startTime || Date.now();

      // Events to monitor (common ones that might cause issues)
      var eventsToMonitor = [
        'click', 'mousedown', 'mouseup', 'mousemove', 'mouseover', 'mouseout',
        'focus', 'blur', 'focusin', 'focusout',
        'input', 'change', 'keydown', 'keyup', 'keypress',
        'scroll', 'resize',
        'DOMContentLoaded', 'load',
        'transitionend', 'animationend',
        'show.bs.collapse', 'shown.bs.collapse', 'hide.bs.collapse', 'hidden.bs.collapse',
        'show.bs.tab', 'shown.bs.tab', 'hide.bs.tab', 'hidden.bs.tab',
        'show.bs.modal', 'shown.bs.modal', 'hide.bs.modal', 'hidden.bs.modal'
      ];

      eventsToMonitor.forEach(function(eventType) {
        document.addEventListener(eventType, function(e) {
          var now = Date.now();
          var secondKey = Math.floor((now - window._debug.startTime) / 1000);

          window._debug.eventCounts[eventType] = (window._debug.eventCounts[eventType] || 0) + 1;
          window._debug.eventsBySecond[secondKey] = (window._debug.eventsBySecond[secondKey] || 0) + 1;

          // Log significant events (limit to avoid memory issues)
          if (window._debug.eventLog.length < 500) {
            var targetId = '';
            if (e.target && e.target.id) {
              targetId = '#' + e.target.id;
            } else if (e.target && e.target.className && typeof e.target.className === 'string') {
              targetId = '.' + e.target.className.split(' ')[0];
            } else if (e.target && e.target.tagName) {
              targetId = e.target.tagName.toLowerCase();
            }

            window._debug.eventLog.push({
              time: now - window._debug.startTime,
              type: eventType,
              target: targetId
            });
          }
        }, true); // Use capture phase to see all events
      });

      console.log('[DEBUG] Event monitor started for: ' + eventsToMonitor.join(', '));
    JS
  end

  # Helper to inject timer/interval monitor
  def inject_timer_monitor
    page.execute_script(<<~JS)
      window._debug = window._debug || {};
      window._debug.timers = {
        setTimeoutCalls: [],
        setIntervalCalls: [],
        activeIntervals: {},
        intervalFireCounts: {}
      };

      // Override setTimeout
      var originalSetTimeout = window.setTimeout;
      window.setTimeout = function(callback, delay) {
        var stack = new Error().stack;
        window._debug.timers.setTimeoutCalls.push({
          time: Date.now() - (window._debug.startTime || Date.now()),
          delay: delay,
          stack: stack ? stack.split('\\n').slice(0, 5).join('\\n') : 'no stack'
        });
        return originalSetTimeout.apply(window, arguments);
      };

      // Override setInterval
      var originalSetInterval = window.setInterval;
      window.setInterval = function(callback, interval) {
        var stack = new Error().stack;
        var id = originalSetInterval.apply(window, arguments);
        window._debug.timers.setIntervalCalls.push({
          id: id,
          interval: interval,
          stack: stack ? stack.split('\\n').slice(0, 5).join('\\n') : 'no stack'
        });
        window._debug.timers.activeIntervals[id] = {
          interval: interval,
          startTime: Date.now()
        };
        window._debug.timers.intervalFireCounts[id] = 0;

        // Wrap callback to count fires
        var originalCallback = callback;
        var wrappedCallback = function() {
          window._debug.timers.intervalFireCounts[id]++;
          if (typeof originalCallback === 'function') {
            originalCallback();
          }
        };

        return id;
      };

      // Override clearInterval
      var originalClearInterval = window.clearInterval;
      window.clearInterval = function(id) {
        delete window._debug.timers.activeIntervals[id];
        return originalClearInterval.apply(window, arguments);
      };

      console.log('[DEBUG] Timer monitor started');
    JS
  end

  # Helper to inject jQuery event handler count monitor
  def inject_jquery_event_monitor
    page.execute_script(<<~JS)
      window._debug = window._debug || {};
      window._debug.jqueryEvents = {};

      // Function to count jQuery event handlers on an element
      window._debug.countJqueryHandlers = function(selector) {
        var counts = {};
        $(selector).each(function() {
          var events = $._data(this, 'events') || {};
          for (var eventType in events) {
            counts[eventType] = (counts[eventType] || 0) + events[eventType].length;
          }
        });
        return counts;
      };

      // Function to get all document-level delegated handlers
      window._debug.getDocumentHandlers = function() {
        var events = $._data(document, 'events') || {};
        var result = {};
        for (var eventType in events) {
          result[eventType] = {
            count: events[eventType].length,
            selectors: events[eventType].map(function(h) {
              return h.selector || '(direct)';
            })
          };
        }
        return result;
      };

      console.log('[DEBUG] jQuery event monitor ready');
    JS
  end

  # Helper to get debug summary
  def get_debug_summary
    page.evaluate_script(<<~JS)
      (function() {
        var debug = window._debug || {};
        var elapsedSeconds = Math.floor((Date.now() - (debug.startTime || Date.now())) / 1000);

        return {
          elapsedSeconds: elapsedSeconds,
          mutations: {
            total: debug.mutationCount || 0,
            perSecond: elapsedSeconds > 0 ? Math.round((debug.mutationCount || 0) / elapsedSeconds) : 0,
            byType: debug.mutationTypes || {},
            topElements: Object.entries(debug.elementMutations || {})
              .sort(function(a, b) { return b[1] - a[1]; })
              .slice(0, 10),
            peakSecond: Object.entries(debug.mutationsBySecond || {})
              .sort(function(a, b) { return b[1] - a[1]; })[0] || ['0', 0]
          },
          events: {
            total: Object.values(debug.eventCounts || {}).reduce(function(a, b) { return a + b; }, 0),
            byCounts: debug.eventCounts || {},
            peakSecond: Object.entries(debug.eventsBySecond || {})
              .sort(function(a, b) { return b[1] - a[1]; })[0] || ['0', 0]
          },
          timers: {
            setTimeoutCalls: (debug.timers || {}).setTimeoutCalls ? debug.timers.setTimeoutCalls.length : 0,
            setIntervalCalls: (debug.timers || {}).setIntervalCalls ? debug.timers.setIntervalCalls.length : 0,
            activeIntervals: Object.keys((debug.timers || {}).activeIntervals || {}).length,
            recentTimeouts: ((debug.timers || {}).setTimeoutCalls || []).slice(-10)
          },
          jqueryDocumentHandlers: debug.getDocumentHandlers ? debug.getDocumentHandlers() : {}
        };
      })()
    JS
  end

  # Helper to get recent activity (for detailed debugging)
  def get_recent_activity
    page.evaluate_script(<<~JS)
      (function() {
        var debug = window._debug || {};
        return {
          recentMutations: (debug.mutationLog || []).slice(-50),
          recentEvents: (debug.eventLog || []).slice(-50)
        };
      })()
    JS
  end

  describe 'search tab switching performance' do
    before :each do
      login
    end

    it 'monitors DOM mutations and events during tab switching' do
      visit '/masters/search'
      finish_page_loading

      # Inject all monitors
      inject_dom_mutation_monitor
      inject_event_monitor
      inject_timer_monitor
      inject_jquery_event_monitor

      # Wait a moment for initial page activity to settle
      sleep 2

      # Reset start time after settling
      page.execute_script('window._debug.startTime = Date.now();')
      page.execute_script('window._debug.mutationCount = 0;')
      page.execute_script('window._debug.mutationsBySecond = {};')
      page.execute_script('window._debug.eventsBySecond = {};')
      page.execute_script('window._debug.eventCounts = {};')

      puts "\n" + '=' * 80
      puts 'MONITORING SEARCH TAB SWITCHING PERFORMANCE'
      puts '=' * 80

      # Test clicking Simple Search tab
      if page.has_button?('Simple Search')
        puts "\n[ACTION] Clicking 'Simple Search' tab..."
        click_button 'Simple Search'
        sleep 3 # Allow time for any cascading activity

        summary = get_debug_summary
        puts "\n[AFTER Simple Search - #{summary['elapsedSeconds']}s elapsed]"
        puts "  Mutations: #{summary.dig('mutations', 'total')} total (#{summary.dig('mutations', 'perSecond')}/sec)"
        puts "  Peak mutation second: #{summary.dig('mutations', 'peakSecond')&.join(' = ')} mutations"
        puts "  Top mutated elements: #{summary.dig('mutations', 'topElements')&.take(5)&.map { |e| "#{e[0]}(#{e[1]})" }&.join(', ')}"
        puts "  Events: #{summary.dig('events', 'total')} total"
        puts "  Peak event second: #{summary.dig('events', 'peakSecond')&.join(' = ')} events"
      end

      # Test clicking Advanced Search tab
      if page.has_button?('Advanced Search')
        puts "\n[ACTION] Clicking 'Advanced Search' tab..."
        click_button 'Advanced Search'
        sleep 3

        summary = get_debug_summary
        puts "\n[AFTER Advanced Search - #{summary['elapsedSeconds']}s elapsed]"
        puts "  Mutations: #{summary.dig('mutations', 'total')} total (#{summary.dig('mutations', 'perSecond')}/sec)"
        puts "  Peak mutation second: #{summary.dig('mutations', 'peakSecond')&.join(' = ')} mutations"
        puts "  Top mutated elements: #{summary.dig('mutations', 'topElements')&.take(5)&.map { |e| "#{e[0]}(#{e[1]})" }&.join(', ')}"
        puts "  Events: #{summary.dig('events', 'total')} total"
        puts "  Peak event second: #{summary.dig('events', 'peakSecond')&.join(' = ')} events"
      end

      # Test clicking report tabs
      @reports.each_with_index do |report, idx|
        report_tab_selector = "a#expand-searchable-report-#{report.alt_resource_name}"
        next unless page.has_css?(report_tab_selector)

        puts "\n[ACTION] Clicking report tab #{idx + 1}: '#{report.name}'..."
        find(report_tab_selector).click
        sleep 3

        summary = get_debug_summary
        puts "\n[AFTER Report #{idx + 1} - #{summary['elapsedSeconds']}s elapsed]"
        puts "  Mutations: #{summary.dig('mutations', 'total')} total (#{summary.dig('mutations', 'perSecond')}/sec)"
        puts "  Peak mutation second: #{summary.dig('mutations', 'peakSecond')&.join(' = ')} mutations"
        puts "  Top mutated elements: #{summary.dig('mutations', 'topElements')&.take(5)&.map { |e| "#{e[0]}(#{e[1]})" }&.join(', ')}"
        puts "  Events: #{summary.dig('events', 'total')} total"
        puts "  Peak event second: #{summary.dig('events', 'peakSecond')&.join(' = ')} events"
      end

      # Final summary
      puts "\n" + '=' * 80
      puts 'FINAL SUMMARY'
      puts '=' * 80
      summary = get_debug_summary

      puts "\nTotal Elapsed Time: #{summary['elapsedSeconds']} seconds"
      puts "\nMutation Summary:"
      puts "  Total mutations: #{summary.dig('mutations', 'total')}"
      puts "  Average per second: #{summary.dig('mutations', 'perSecond')}"
      puts "  Peak second: #{summary.dig('mutations', 'peakSecond')&.first} with #{summary.dig('mutations', 'peakSecond')&.last} mutations"
      puts "  By type: #{summary.dig('mutations', 'byType')}"
      puts "  Top 10 mutated elements:"
      summary.dig('mutations', 'topElements')&.each do |elem, count|
        puts "    #{elem}: #{count} mutations"
      end

      puts "\nEvent Summary:"
      puts "  Total events: #{summary.dig('events', 'total')}"
      puts "  Peak second: #{summary.dig('events', 'peakSecond')&.first} with #{summary.dig('events', 'peakSecond')&.last} events"
      puts "  By type (top 10):"
      summary.dig('events', 'byCounts')&.sort_by { |_k, v| -v }&.take(10)&.each do |event_type, count|
        puts "    #{event_type}: #{count}"
      end

      puts "\nTimer Summary:"
      puts "  setTimeout calls: #{summary.dig('timers', 'setTimeoutCalls')}"
      puts "  setInterval calls: #{summary.dig('timers', 'setIntervalCalls')}"
      puts "  Active intervals: #{summary.dig('timers', 'activeIntervals')}"

      puts "\njQuery Document-Level Handlers:"
      summary['jqueryDocumentHandlers']&.each do |event_type, info|
        puts "  #{event_type}: #{info['count']} handlers"
        if info['selectors']&.length.to_i > 0
          puts "    Selectors: #{info['selectors']&.uniq&.take(5)&.join(', ')}"
        end
      end

      # Check for warning signs
      puts "\n" + '=' * 80
      puts 'POTENTIAL ISSUES DETECTED'
      puts '=' * 80

      issues_found = false

      if summary.dig('mutations', 'perSecond').to_i > 50
        puts "⚠️  HIGH MUTATION RATE: #{summary.dig('mutations', 'perSecond')} mutations/second"
        puts '   This could cause password manager plugins to constantly rescan the page'
        issues_found = true
      end

      if summary.dig('mutations', 'peakSecond')&.last.to_i > 200
        puts "⚠️  MUTATION SPIKE: #{summary.dig('mutations', 'peakSecond')&.last} mutations in second #{summary.dig('mutations', 'peakSecond')&.first}"
        issues_found = true
      end

      if summary.dig('events', 'byCounts', 'focus').to_i > 50
        puts "⚠️  EXCESSIVE FOCUS EVENTS: #{summary.dig('events', 'byCounts', 'focus')} focus events"
        puts '   Password managers often react to focus events on form fields'
        issues_found = true
      end

      if summary.dig('timers', 'activeIntervals').to_i > 5
        puts "⚠️  MANY ACTIVE INTERVALS: #{summary.dig('timers', 'activeIntervals')} intervals running"
        issues_found = true
      end

      # Check for duplicate jQuery handlers
      summary['jqueryDocumentHandlers']&.each do |event_type, info|
        if info['count'].to_i > 10
          puts "⚠️  MANY #{event_type.upcase} HANDLERS: #{info['count']} document-level handlers"
          issues_found = true
        end
      end

      puts 'No obvious issues detected.' unless issues_found
      puts '=' * 80

      # This test always passes - it's for debugging output
      expect(true).to be true
    end

    it 'monitors for continuous activity after tab click' do
      visit '/masters/search'
      finish_page_loading

      # Inject all monitors
      inject_dom_mutation_monitor
      inject_event_monitor

      # Click a tab and then just wait to see if activity continues
      if page.has_button?('Simple Search')
        click_button 'Simple Search'
        finish_page_loading
      end

      puts "\n" + '=' * 80
      puts 'MONITORING FOR CONTINUOUS ACTIVITY (5 seconds after tab click)'
      puts '=' * 80

      # Reset counters
      page.execute_script('window._debug.startTime = Date.now();')
      page.execute_script('window._debug.mutationCount = 0;')
      page.execute_script('window._debug.mutationsBySecond = {};')
      page.execute_script('window._debug.eventsBySecond = {};')
      page.execute_script('window._debug.eventCounts = {};')
      page.execute_script('window._debug.mutationLog = [];')
      page.execute_script('window._debug.eventLog = [];')

      # Monitor each second
      5.times do |i|
        sleep 1
        mutations_this_second = page.evaluate_script("window._debug.mutationsBySecond[#{i}] || 0")
        events_this_second = page.evaluate_script("window._debug.eventsBySecond[#{i}] || 0")
        puts "Second #{i + 1}: #{mutations_this_second} mutations, #{events_this_second} events"

        if mutations_this_second > 10 || events_this_second > 20
          activity = get_recent_activity
          puts "  Recent mutations: #{activity['recentMutations']&.last(5)&.map { |m| "#{m['type']}@#{m['target']}" }&.join(', ')}"
          puts "  Recent events: #{activity['recentEvents']&.last(5)&.map { |e| "#{e['type']}@#{e['target']}" }&.join(', ')}"
        end
      end

      summary = get_debug_summary
      avg_mutations = summary.dig('mutations', 'perSecond').to_i

      if avg_mutations > 2
        puts "\n⚠️  WARNING: Continuous activity detected (#{avg_mutations} mutations/sec average)"
        puts '   This may cause browser plugins to continuously process the page.'

        # Get more detail on what's mutating
        puts "\n   Most active elements:"
        summary.dig('mutations', 'topElements')&.take(5)&.each do |elem, count|
          puts "     #{elem}: #{count} mutations"
        end
      else
        puts "\n✓ Activity levels appear normal after tab switch"
      end

      expect(true).to be true
    end

    it 'detects duplicate event handler bindings' do
      visit '/masters/search'
      finish_page_loading

      inject_jquery_event_monitor

      puts "\n" + '=' * 80
      puts 'CHECKING FOR DUPLICATE EVENT HANDLER BINDINGS'
      puts '=' * 80

      # Get initial handler counts
      initial_handlers = page.evaluate_script('window._debug.getDocumentHandlers()')

      puts "\nInitial document-level handlers:"
      initial_handlers.each do |event_type, info|
        puts "  #{event_type}: #{info['count']} handlers"
      end

      # Simulate some interactions that might cause re-binding
      3.times do |i|
        if page.has_button?('Simple Search')
          click_button 'Simple Search'
          finish_page_loading
        end

        if page.has_button?('Advanced Search')
          click_button 'Advanced Search'
          finish_page_loading
        end
      end

      # Get handler counts after interactions
      final_handlers = page.evaluate_script('window._debug.getDocumentHandlers()')

      puts "\nAfter 3 tab switch cycles:"
      duplicates_found = false
      final_handlers.each do |event_type, info|
        initial_count = initial_handlers.dig(event_type, 'count') || 0
        final_count = info['count']
        diff = final_count - initial_count

        status = diff.positive? ? "⚠️  +#{diff}" : '✓'
        puts "  #{event_type}: #{final_count} handlers #{status}"

        if diff.positive?
          duplicates_found = true
          puts "    Selectors: #{info['selectors']&.join(', ')}"
        end
      end

      if duplicates_found
        puts "\n⚠️  DUPLICATE HANDLERS DETECTED!"
        puts '   Event handlers are being bound multiple times.'
        puts '   This can cause events to fire multiple times per interaction.'
      else
        puts "\n✓ No duplicate handlers detected"
      end

      expect(true).to be true
    end

    it 'identifies input field mutations that trigger password managers' do
      visit '/masters/search'
      finish_page_loading

      # Specific monitoring for input/password field related mutations
      page.execute_script(<<~JS)
        window._debug = window._debug || {};
        window._debug.inputMutations = [];
        window._debug.formMutations = [];
        window._debug.startTime = Date.now();

        window._debug.inputObserver = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            var target = mutation.target;
            var isInput = target.tagName === 'INPUT' ||
                          target.tagName === 'TEXTAREA' ||
                          target.closest && target.closest('input, textarea, form, .form-group');

            if (isInput || target.tagName === 'FORM' || (target.classList && target.classList.contains('form-group'))) {
              window._debug.inputMutations.push({
                time: Date.now() - window._debug.startTime,
                type: mutation.type,
                tagName: target.tagName,
                id: target.id || null,
                className: target.className || null,
                attributeName: mutation.attributeName || null,
                inputType: target.type || null
              });
            }

            // Check if mutation is near password-type indicators
            if (mutation.type === 'attributes') {
              var affectsPasswordIndicators =
                mutation.attributeName === 'type' ||
                mutation.attributeName === 'autocomplete' ||
                mutation.attributeName === 'name' ||
                mutation.attributeName === 'value' ||
                mutation.attributeName === 'placeholder';

              if (affectsPasswordIndicators && target.tagName === 'INPUT') {
                window._debug.formMutations.push({
                  time: Date.now() - window._debug.startTime,
                  target: '#' + (target.id || target.name || 'unknown'),
                  attribute: mutation.attributeName,
                  oldValue: mutation.oldValue,
                  newValue: target.getAttribute(mutation.attributeName)
                });
              }
            }
          });
        });

        window._debug.inputObserver.observe(document.body, {
          childList: true,
          attributes: true,
          characterData: true,
          subtree: true,
          attributeOldValue: true
        });

        console.log('[DEBUG] Input/form mutation observer started');
      JS

      puts "\n" + '=' * 80
      puts 'MONITORING INPUT FIELD MUTATIONS (Password Manager Triggers)'
      puts '=' * 80

      # Perform tab switches
      3.times do
        if page.has_button?('Simple Search')
          click_button 'Simple Search'
          sleep 0.5
        end
        if page.has_button?('Advanced Search')
          click_button 'Advanced Search'
          sleep 0.5
        end
      end

      # Wait for any delayed mutations
      sleep 2

      input_mutations = page.evaluate_script('window._debug.inputMutations')
      form_mutations = page.evaluate_script('window._debug.formMutations')

      puts "\nInput/Form Related Mutations: #{input_mutations&.length || 0}"
      if input_mutations&.any?
        puts "\nSample mutations (last 20):"
        input_mutations&.last(20)&.each do |m|
          puts "  #{m['time']}ms: #{m['type']} on #{m['tagName']}##{m['id']} (#{m['attributeName']})"
        end
      end

      puts "\nPassword-Indicator Attribute Changes: #{form_mutations&.length || 0}"
      if form_mutations&.any?
        puts "\nThese attribute changes may trigger password managers:"
        form_mutations.each do |m|
          puts "  #{m['time']}ms: #{m['target']}.#{m['attribute']} changed from '#{m['oldValue']}' to '#{m['newValue']}'"
        end
      end

      # Count inputs being added/removed
      inputs_added = input_mutations&.count { |m| m['type'] == 'childList' } || 0
      if inputs_added > 20
        puts "\n⚠️  HIGH INPUT CHURN: #{inputs_added} input-related childList mutations"
        puts '   Form fields may be getting destroyed and recreated frequently.'
      end

      expect(true).to be true
    end

    it 'tracks detailed attribute changes to identify the source of mutations' do
      visit '/masters/search'
      finish_page_loading

      # Inject detailed attribute change tracking
      page.execute_script(<<~JS)
        window._debug = window._debug || {};
        window._debug.attributeChanges = [];
        window._debug.startTime = Date.now();

        // Group attribute changes by element+attribute combination
        window._debug.attributeGroups = {};

        window._debug.attrObserver = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            if (mutation.type === 'attributes') {
              var target = mutation.target;
              var id = target.id || '';
              var classes = (typeof target.className === 'string') ? target.className.split(' ').slice(0, 3).join('.') : '';
              var tag = target.tagName || '';
              var elementKey = tag + (id ? '#' + id : '') + (classes ? '.' + classes : '');
              var groupKey = elementKey + '@' + mutation.attributeName;

              window._debug.attributeGroups[groupKey] = (window._debug.attributeGroups[groupKey] || 0) + 1;

              if (window._debug.attributeChanges.length < 200) {
                window._debug.attributeChanges.push({
                  time: Date.now() - window._debug.startTime,
                  element: elementKey,
                  attribute: mutation.attributeName,
                  oldValue: mutation.oldValue ? mutation.oldValue.substring(0, 100) : null,
                  newValue: target.getAttribute(mutation.attributeName) ?
                            target.getAttribute(mutation.attributeName).substring(0, 100) : null
                });
              }
            }
          });
        });

        window._debug.attrObserver.observe(document.body, {
          attributes: true,
          subtree: true,
          attributeOldValue: true
        });

        console.log('[DEBUG] Detailed attribute observer started');
      JS

      puts "\n" + '=' * 80
      puts 'TRACKING DETAILED ATTRIBUTE CHANGES'
      puts '=' * 80

      # Perform tab switches
      if page.has_button?('Simple Search')
        puts "\n[ACTION] Clicking Simple Search..."
        click_button 'Simple Search'
        sleep 1
      end

      if page.has_button?('Advanced Search')
        puts "\n[ACTION] Clicking Advanced Search..."
        click_button 'Advanced Search'
        sleep 1
      end

      # Click a report tab if available
      @reports.each_with_index do |report, idx|
        break if idx >= 1 # Just one report tab
        report_tab_selector = "a#expand-searchable-report-#{report.alt_resource_name}"
        next unless page.has_css?(report_tab_selector)

        puts "\n[ACTION] Clicking report tab: '#{report.name}'..."
        find(report_tab_selector).click
        sleep 1
      end

      # Get attribute change groups
      attr_groups = page.evaluate_script('window._debug.attributeGroups')
      attr_changes = page.evaluate_script('window._debug.attributeChanges')

      puts "\n" + '-' * 80
      puts 'ATTRIBUTE CHANGE FREQUENCY BY ELEMENT+ATTRIBUTE'
      puts '-' * 80

      attr_groups&.sort_by { |_k, v| -v }&.take(20)&.each do |key, count|
        puts "  #{count}x: #{key}"
      end

      puts "\n" + '-' * 80
      puts 'SAMPLE ATTRIBUTE CHANGES (showing value transitions)'
      puts '-' * 80

      # Group by attribute to show what's changing
      changes_by_attr = {}
      attr_changes&.each do |change|
        key = "#{change['element']}@#{change['attribute']}"
        changes_by_attr[key] ||= []
        changes_by_attr[key] << change if changes_by_attr[key].length < 3
      end

      changes_by_attr.each do |key, changes|
        next if changes.empty?

        puts "\n  #{key}:"
        changes.each do |c|
          old_val = c['oldValue'] || '(none)'
          new_val = c['newValue'] || '(none)'
          puts "    #{c['time']}ms: '#{old_val}' → '#{new_val}'"
        end
      end

      # Identify problematic patterns
      puts "\n" + '=' * 80
      puts 'ANALYSIS'
      puts '=' * 80

      issues = []

      # Check for class toggling (common cause of constant mutations)
      class_toggles = attr_groups&.select { |k, v| k.include?('@class') && v > 5 } || {}
      if class_toggles.any?
        puts "\n⚠️  FREQUENT CLASS CHANGES DETECTED:"
        class_toggles.sort_by { |_k, v| -v }.take(10).each do |key, count|
          puts "    #{count}x: #{key}"
        end
        issues << 'class_toggling'
      end

      # Check for aria-expanded changes (Bootstrap collapse triggers)
      aria_changes = attr_groups&.select { |k, _v| k.include?('aria-') } || {}
      if aria_changes.values.sum > 20
        puts "\n⚠️  MANY ARIA ATTRIBUTE CHANGES: #{aria_changes.values.sum} total"
        aria_changes.sort_by { |_k, v| -v }.take(5).each do |key, count|
          puts "    #{count}x: #{key}"
        end
        issues << 'aria_changes'
      end

      # Check for style changes
      style_changes = attr_groups&.select { |k, _v| k.include?('@style') } || {}
      if style_changes.values.sum > 20
        puts "\n⚠️  MANY STYLE ATTRIBUTE CHANGES: #{style_changes.values.sum} total"
        style_changes.sort_by { |_k, v| -v }.take(5).each do |key, count|
          puts "    #{count}x: #{key}"
        end
        issues << 'style_changes'
      end

      if issues.empty?
        puts "\n✓ No obviously problematic patterns detected"
      else
        puts "\n" + '-' * 80
        puts 'RECOMMENDATIONS'
        puts '-' * 80

        if issues.include?('class_toggling')
          puts "• Class toggling may be happening in a loop or unnecessarily."
          puts "  Check JavaScript that adds/removes classes repeatedly."
          puts "  Consider using CSS transitions instead of class toggles where possible."
        end

        if issues.include?('aria_changes')
          puts "• Many ARIA changes may indicate Bootstrap collapse/show events cascading."
          puts "  Check for event handlers that trigger additional collapse/expand."
        end

        if issues.include?('style_changes')
          puts "• Direct style manipulation may be happening frequently."
          puts "  Consider using CSS classes instead of inline styles."
        end
      end

      expect(true).to be true
    end
  end
end
