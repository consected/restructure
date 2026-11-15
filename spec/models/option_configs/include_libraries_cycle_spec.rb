# frozen_string_literal: true

# Tests that OptionConfigs::ExtraOptions.include_libraries terminates when a
# config library reference forms a cycle (self-reference A -> A, or A -> B -> A).
#
# Background (issue #676): include_libraries expands every `# @library cat name`
# directive by replacing it with the library body and re-scanning. The library
# body can itself contain directives (legitimate nesting). Without cycle
# protection a self- or mutually-referencing library — which can occur in
# production when a historical library version is resolved via version_at —
# expands without bound, growing the prepared options text to hundreds of
# thousands of lines and eventually failing YAML parsing. The fix adds the same
# `seen` guard already used by requested_libraries so each library is sourced at
# most once and repeated references are neutralised.

require 'rails_helper'

RSpec.describe 'OptionConfigs::ExtraOptions.include_libraries cycle protection', type: :model do
  let(:described) { OptionConfigs::ExtraOptions }

  it 'expands legitimately nested libraries without a cycle' do
    allow(Admin::ConfigLibrary).to receive(:content_named)
      .with('cat', 'a', format: :yaml).and_return("body_a: 1\n# @library cat b")
    allow(Admin::ConfigLibrary).to receive(:content_named)
      .with('cat', 'b', format: :yaml).and_return('body_b: 2')

    result = described.include_libraries("# @library cat a\ntop: level")

    expect(result).to include('body_a: 1')
    expect(result).to include('body_b: 2')
    # No live directives remain, so it terminated cleanly
    expect(result.scan(OptionConfigs::ExtraOptions::LibraryMatchRegex)).to be_empty
  end

  it 'terminates and neutralises a self-referencing library' do
    allow(Admin::ConfigLibrary).to receive(:content_named)
      .with('cyccat', 'cyclib', format: :yaml)
      .and_return("body_key: value\n# @library cyccat cyclib")

    result = nil
    expect do
      Timeout.timeout(5) { result = described.include_libraries("# @library cyccat cyclib\ntop: level") }
    end.not_to raise_error

    # The body was sourced exactly once
    expect(result.scan('body_key: value').length).to eq 1
    # The repeated self-reference was neutralised, not expanded again
    expect(result).to include('@library_cycle_skipped cyccat cyclib')
    # No directive still matches the include regex, so the loop converged
    expect(result.scan(OptionConfigs::ExtraOptions::LibraryMatchRegex)).to be_empty
    # The output stays small rather than exploding
    expect(result.length).to be < 1000
  end

  it 'terminates and neutralises a mutual A -> B -> A cycle' do
    allow(Admin::ConfigLibrary).to receive(:content_named)
      .with('cat', 'a', format: :yaml).and_return("body_a: 1\n# @library cat b")
    allow(Admin::ConfigLibrary).to receive(:content_named)
      .with('cat', 'b', format: :yaml).and_return("body_b: 2\n# @library cat a")

    result = nil
    expect do
      Timeout.timeout(5) { result = described.include_libraries("# @library cat a\ntop: level") }
    end.not_to raise_error

    # Each library body is sourced exactly once
    expect(result.scan('body_a: 1').length).to eq 1
    expect(result.scan('body_b: 2').length).to eq 1
    # The reference that closed the cycle was neutralised
    expect(result).to include('@library_cycle_skipped cat a')
    expect(result.scan(OptionConfigs::ExtraOptions::LibraryMatchRegex)).to be_empty
    expect(result.length).to be < 1000
  end

  # The production trigger for issue #676 was the versioned path: a historical
  # library version resolved via version_at can produce a cycle when the library's
  # own content at that point in time references itself. The cycle guard must work
  # identically when content_named_at is used instead of content_named.
  it 'terminates and neutralises a self-referencing library when resolved via version_at' do
    version_at = Time.now
    allow(Admin::ConfigLibrary).to receive(:content_named_at)
      .with('cyccat', 'cyclib', format: :yaml, at: version_at)
      .and_return("body_key: versioned_value\n# @library cyccat cyclib")

    result = nil
    expect do
      Timeout.timeout(5) { result = described.include_libraries("# @library cyccat cyclib\ntop: level", version_at:) }
    end.not_to raise_error

    # The body was sourced exactly once
    expect(result.scan('body_key: versioned_value').length).to eq 1
    # The repeated self-reference was neutralised
    expect(result).to include('@library_cycle_skipped cyccat cyclib')
    # No live directives remain
    expect(result.scan(OptionConfigs::ExtraOptions::LibraryMatchRegex)).to be_empty
    expect(result.length).to be < 1000
  end

  it 'terminates and neutralises a mutual A -> B -> A cycle when resolved via version_at' do
    version_at = Time.now
    allow(Admin::ConfigLibrary).to receive(:content_named_at)
      .with('cat', 'a', format: :yaml, at: version_at).and_return("body_a: versioned_1\n# @library cat b")
    allow(Admin::ConfigLibrary).to receive(:content_named_at)
      .with('cat', 'b', format: :yaml, at: version_at).and_return("body_b: versioned_2\n# @library cat a")

    result = nil
    expect do
      Timeout.timeout(5) { result = described.include_libraries("# @library cat a\ntop: level", version_at:) }
    end.not_to raise_error

    # Each library body is sourced exactly once
    expect(result.scan('body_a: versioned_1').length).to eq 1
    expect(result.scan('body_b: versioned_2').length).to eq 1
    # The back-reference that closed the cycle was neutralised
    expect(result).to include('@library_cycle_skipped cat a')
    expect(result.scan(OptionConfigs::ExtraOptions::LibraryMatchRegex)).to be_empty
    expect(result.length).to be < 1000
  end
end
