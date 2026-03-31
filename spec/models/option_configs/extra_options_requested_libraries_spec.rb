# frozen_string_literal: true

# Tests for OptionConfigs::ExtraOptions.requested_libraries with nested/transitive library resolution.
#
# The requested_libraries method scans content for `# @library category name` references
# and returns an array of {category:, name:} hashes. It resolves nested references:
# when a referenced library itself contains `# @library` lines pointing to other libraries,
# those transitive dependencies are also included in the result.
#
# Issue #1007: The list of libraries in a dynamic definition admin panel misses some
# because nested/transitive library references are not followed.

require 'rails_helper'

RSpec.describe OptionConfigs::ExtraOptions, type: :model do
  include ModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    @rand_suffix = rand(1_000_000_000)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  describe '.requested_libraries' do
    context 'with no library references' do
      it 'returns an empty array when content has no @library lines' do
        content = "some_field:\n  label: Test\n"
        result = described_class.requested_libraries(content)
        expect(result).to eq([])
      end
    end

    context 'with direct (non-nested) library references' do
      before :all do
        @direct_cat = "direct_cat_#{@rand_suffix}"
        @direct_name = "direct_lib_#{@rand_suffix}"

        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @direct_name,
          category: @direct_cat,
          format: 'yaml',
          options: "standalone_field:\n  label: Standalone"
        )
      end

      it 'returns the directly referenced library' do
        content = "some_config:\n  label: Test\n# @library #{@direct_cat} #{@direct_name}\n"
        result = described_class.requested_libraries(content)
        expect(result).to include({ category: @direct_cat, name: @direct_name })
      end

      it 'returns multiple directly referenced libraries' do
        other_name = "direct_lib2_#{@rand_suffix}"
        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: other_name,
          category: @direct_cat,
          format: 'yaml',
          options: "another_field:\n  label: Another"
        )

        content = "# @library #{@direct_cat} #{@direct_name}\n# @library #{@direct_cat} #{other_name}\n"
        result = described_class.requested_libraries(content)
        expect(result).to include({ category: @direct_cat, name: @direct_name })
        expect(result).to include({ category: @direct_cat, name: other_name })
      end
    end

    context 'with one level of nested library references' do
      before :all do
        @nested_cat = "nested_cat_#{@rand_suffix}"
        @lib_a_name = "lib_a_#{@rand_suffix}"
        @lib_b_name = "lib_b_#{@rand_suffix}"

        # Library A is standalone - no further @library references
        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @lib_a_name,
          category: @nested_cat,
          format: 'yaml',
          options: "field_a:\n  label: Field A"
        )

        # Library B references library A
        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @lib_b_name,
          category: @nested_cat,
          format: 'yaml',
          options: "field_b:\n  label: Field B\n# @library #{@nested_cat} #{@lib_a_name}"
        )
      end

      it 'returns both the directly referenced library and its nested dependency' do
        # Content only references library B directly
        content = "config:\n  label: Test\n# @library #{@nested_cat} #{@lib_b_name}\n"
        result = described_class.requested_libraries(content)

        # Should include library B (direct reference)
        expect(result).to include({ category: @nested_cat, name: @lib_b_name })
        # Should also include library A (nested reference from library B's content)
        expect(result).to include({ category: @nested_cat, name: @lib_a_name })
      end
    end

    context 'with deeper nesting (A -> B -> C)' do
      before :all do
        @deep_cat = "deep_cat_#{@rand_suffix}"
        @lib_c_name = "lib_c_#{@rand_suffix}"
        @lib_d_name = "lib_d_#{@rand_suffix}"
        @lib_e_name = "lib_e_#{@rand_suffix}"

        # Library C is standalone
        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @lib_c_name,
          category: @deep_cat,
          format: 'yaml',
          options: "field_c:\n  label: Field C"
        )

        # Library D references library C
        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @lib_d_name,
          category: @deep_cat,
          format: 'yaml',
          options: "field_d:\n  label: Field D\n# @library #{@deep_cat} #{@lib_c_name}"
        )

        # Library E references library D
        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @lib_e_name,
          category: @deep_cat,
          format: 'yaml',
          options: "field_e:\n  label: Field E\n# @library #{@deep_cat} #{@lib_d_name}"
        )
      end

      it 'returns all transitively referenced libraries through multiple levels' do
        # Content only references library E directly
        content = "config:\n  label: Test\n# @library #{@deep_cat} #{@lib_e_name}\n"
        result = described_class.requested_libraries(content)

        # Should include library E (direct reference)
        expect(result).to include({ category: @deep_cat, name: @lib_e_name })
        # Should include library D (referenced by E)
        expect(result).to include({ category: @deep_cat, name: @lib_d_name })
        # Should include library C (referenced by D)
        expect(result).to include({ category: @deep_cat, name: @lib_c_name })
      end
    end

    context 'with circular references' do
      before :all do
        @circ_cat = "circ_cat_#{@rand_suffix}"
        @lib_x_name = "lib_x_#{@rand_suffix}"
        @lib_y_name = "lib_y_#{@rand_suffix}"

        # Create both libraries first without cross-references (validation prevents forward refs)
        lib_x = Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @lib_x_name,
          category: @circ_cat,
          format: 'yaml',
          options: "field_x:\n  label: Field X"
        )

        Admin::ConfigLibrary.create!(
          current_admin: @admin,
          name: @lib_y_name,
          category: @circ_cat,
          format: 'yaml',
          options: "field_y:\n  label: Field Y\n# @library #{@circ_cat} #{@lib_x_name}"
        )

        # Now update library X to reference library Y (creating the circular reference)
        lib_x.current_admin = @admin
        lib_x.update!(options: "field_x:\n  label: Field X\n# @library #{@circ_cat} #{@lib_y_name}")
      end

      it 'handles circular references without infinite recursion and returns both libraries' do
        content = "config:\n  label: Test\n# @library #{@circ_cat} #{@lib_x_name}\n"
        result = described_class.requested_libraries(content)

        # Should include both libraries without hanging or raising an error
        expect(result).to include({ category: @circ_cat, name: @lib_x_name })
        expect(result).to include({ category: @circ_cat, name: @lib_y_name })
      end

      it 'does not include duplicate entries for the same library' do
        content = "config:\n  label: Test\n# @library #{@circ_cat} #{@lib_x_name}\n"
        result = described_class.requested_libraries(content)

        # Each library should appear only once despite the circular reference
        x_entries = result.select { |r| r[:category] == @circ_cat && r[:name] == @lib_x_name }
        y_entries = result.select { |r| r[:category] == @circ_cat && r[:name] == @lib_y_name }
        expect(x_entries.length).to eq(1)
        expect(y_entries.length).to eq(1)
      end
    end
  end
end
