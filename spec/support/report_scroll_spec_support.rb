# frozen_string_literal: true

# Purpose: Record report-specific scroll calls for system specs without relying on viewport pixels.
module ReportScrollSpecSupport
  ReportScrollTrackerScript = <<~JS
    window.issue1522ReportScrollTargets = [];
    window.issue1522ReportPositionCalls = [];
    window.issue1522WindowScrollEvents = [];
    if (!window.issue1522WindowScrollTrackingInstalled) {
      window.addEventListener('scroll', function() {
        window.issue1522WindowScrollEvents.push(window.scrollY);
      }, { passive: true });
      window.issue1522WindowScrollTrackingInstalled = true;
    }
    (function() {
      function targetSelectors(target) {
        if (typeof target === 'string') return [target];
        if (target && target.jquery) {
          return target.toArray().map(function(element) {
            if (element.id) return '#' + element.id;
            if (element.className && typeof element.className === 'string') {
              return '.' + element.className.trim().split(/\s+/).join('.');
            }
            return element.tagName.toLowerCase();
          });
        }
        if (target && target.nodeType === 1) {
          return [target.id ? '#' + target.id : target.tagName.toLowerCase()];
        }
        return [];
      }

      function install() {
        var jquery = window.jQuery || window.$;
        var scroll_to_ready = false;
        var method_ready = false;
        var position_ready = false;

        if (jquery && typeof jquery.scrollTo === 'function') {
          if (!jquery.scrollTo.issue1522Spy) {
            var original_scroll_to = jquery.scrollTo;
            var wrapped_scroll_to = function(target) {
              window.issue1522ReportScrollTargets.push.apply(
                window.issue1522ReportScrollTargets,
                targetSelectors(target)
              );
              return original_scroll_to.apply(this, arguments);
            };
            Object.keys(original_scroll_to).forEach(function(key) {
              wrapped_scroll_to[key] = original_scroll_to[key];
            });
            wrapped_scroll_to.issue1522Spy = true;
            jquery.scrollTo = wrapped_scroll_to;
          }
          scroll_to_ready = true;
        }

        if (jquery && jquery.fn && typeof jquery.fn.scrollTo === 'function') {
          if (!jquery.fn.scrollTo.issue1522Spy) {
            var original_scroll_to_method = jquery.fn.scrollTo;
            var wrapped_scroll_to_method = function(target) {
              window.issue1522ReportScrollTargets.push.apply(
                window.issue1522ReportScrollTargets,
                targetSelectors(target)
              );
              return original_scroll_to_method.apply(this, arguments);
            };
            Object.keys(original_scroll_to_method).forEach(function(key) {
              wrapped_scroll_to_method[key] = original_scroll_to_method[key];
            });
            wrapped_scroll_to_method.issue1522Spy = true;
            jquery.fn.scrollTo = wrapped_scroll_to_method;
          }
          method_ready = true;
        }

        if (window._fpa && window._fpa.reports &&
            typeof window._fpa.reports.report_position_buttons === 'function') {
          if (!window._fpa.reports.report_position_buttons.issue1522Spy) {
            var original_position_buttons = window._fpa.reports.report_position_buttons;
            var wrapped_position_buttons = function(location, should_scroll) {
              window.issue1522ReportPositionCalls.push({
                location: location,
                shouldScroll: should_scroll !== false
              });
              return original_position_buttons.apply(this, arguments);
            };
            Object.keys(original_position_buttons).forEach(function(key) {
              wrapped_position_buttons[key] = original_position_buttons[key];
            });
            wrapped_position_buttons.issue1522Spy = true;
            window._fpa.reports.report_position_buttons = wrapped_position_buttons;
          }
          position_ready = true;
        }

        window.issue1522ReportScrollSpyInstalled =
          scroll_to_ready && method_ready && position_ready;
        return window.issue1522ReportScrollSpyInstalled;
      }

      install();
      if (!window.issue1522ReportScrollSpyInstalled) {
        var interval = window.setInterval(function() {
          if (install()) window.clearInterval(interval);
        }, 10);
      }
    })();
  JS

  def track_report_scroll_calls
    page.execute_script(ReportScrollTrackerScript)
    expect_report_scroll_spy_installed
  end

  def with_report_scroll_tracking_on_next_page_load
    result = page.driver.browser.execute_cdp(
      'Page.addScriptToEvaluateOnNewDocument',
      source: ReportScrollTrackerScript
    )
    yield
  ensure
    if result
      page.driver.browser.execute_cdp(
        'Page.removeScriptToEvaluateOnNewDocument',
        identifier: result['identifier']
      )
    end
  end

  def expect_report_scroll_spy_installed
    installed = page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      const started = Date.now();
      const check = () => {
        if (window.issue1522ReportScrollSpyInstalled) return done(true);
        if (Date.now() - started > 10_000) return done(false);
        window.setTimeout(check, 10);
      };
      check();
    JS
    expect(installed).to be(true), 'Expected report scroll spies to be installed before the action'
  end

  def expect_no_report_results_scroll
    targets = page.evaluate_script('window.issue1522ReportScrollTargets')
    expect(targets).not_to include('.report-results-block')
  end

  def expect_no_report_navigation_scroll
    targets = page.evaluate_script('window.issue1522ReportScrollTargets')
    expect(targets).not_to include('.report-results-block', '#body-top')
  end

  def expect_no_outer_page_scroll
    expect(page.evaluate_script('window.issue1522WindowScrollEvents')).to be_empty
  end

  def expect_report_scroll_target(target)
    expect(page.evaluate_script('window.issue1522ReportScrollTargets')).to include(target)
    expected_location = target == '#body-top' ? 'go-to-form' : 'go-to-results'
    expect(page.evaluate_script('window.issue1522ReportPositionCalls')).to include(
      a_hash_including('location' => expected_location, 'shouldScroll' => true)
    )
  end
end
