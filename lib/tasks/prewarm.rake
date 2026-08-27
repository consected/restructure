# frozen_string_literal: true

namespace :prewarm do
  desc 'Warm compiled Handlebars template artifacts for one representative user per access variant (issue #1362)'
  task templates: :environment do
    Prewarm::Runner.run
  end
end
