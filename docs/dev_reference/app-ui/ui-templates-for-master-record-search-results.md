# Handlebars Template Flow Hierarchy

- [search-results-template](/app/views/masters/_search_results_master_tabs.html.erb)
  - [master_panel_heading](/app/views/masters/_search_results_master_tabs.html.erb)
    - [master_panel_heading_inner](/app/views/masters/_search_results_master_tabs.html.erb)
      - [show_result_caption](/app/views/common_templates/_common_template_result.html.erb)
      - [rank_button](/app/views/common_templates/_common_template_result.html.erb)
      - [edit_item_button](/app/views/common_templates/_common_template_result.html.erb)
    - [master_panel_collapse_button](/app/views/masters/_search_results_master_tabs.html.erb)
  - [master_main](/app/views/masters/_search_results_master_tabs.html.erb)
    - [master_main_inner](/app/views/masters/_search_results_master_tabs.html.erb)
      - [master_tabs](/app/views/masters/_search_results_master_tabs.html.erb)
        - [master_tabs_item](/app/views/masters/_search_results_master_tabs_item.html.erb)
          - [tab_dropdown_toggle](/app/views/masters/_search_results_master_tabs_item.html.erb)
          - [tab_item_link](/app/views/masters/_search_results_master_tabs_item.html.erb)
      - [master_main_panel_body](/app/views/masters/_search_results_master_tabs.html.erb)
        - [category_panel_details](/app/views/masters/_search_results_category_panel.html.erb)
          - [player-infos-list-template](/app/views/common_templates/_search_results_template.html.erb)
            - [common_template_list](/app/views/common_templates/_common_template_list.html.erb)
              - [common_template_list_new_button_container](/app/views/common_templates/_common_template_list.html.erb)
              - [player-info-result-template](/app/views/common_templates/_search_results_template.html.erb)
                - [common_template_result](/app/views/common_templates/_common_template_result.html.erb)
                  - [common_template_result_inner](/app/views/common_templates/_common_template_result.html.erb)
                    - [edit_item_button](/app/views/common_templates/_common_template_result.html.erb)
                    - [rank_button](/app/views/common_templates/_common_template_result.html.erb)
                    - [activity_log_common_template_show_button](/app/views/common_templates/_common_template_result.html.erb)
                    - [show_result_caption](/app/views/common_templates/_common_template_result.html.erb)
                    - [common_template_result_fields](/app/views/common_templates/_common_template_result.html.erb)
                      - [common_template_result_field](/app/views/common_templates/_common_template_result.html.erb)
                        - [field_value_substitution](/app/views/common_templates/_common_template_result.html.erb)
                        - [field_label_substitution](/app/views/common_templates/_common_template_result.html.erb)
                      - [custom_block_attrs_html](/app/views/common_templates/_common_template_result.html.erb)
                    - [activity_log_references](/app/views/common_templates/_common_template_result.html.erb)
                      - [activity-log-reference-result-template](/app/views/common_templates/_search_results_template.html.erb)
                        - *(recursive common_template_result)*
                    - [update_metadata](/app/views/common_templates/_common_template_result.html.erb)
                  - [custom_block_attrs_html](/app/views/common_templates/_common_template_result.html.erb)
          - [player-contacts-list-template](/app/views/common_templates/_search_results_template.html.erb)
            - *(same structure as player-infos-list-template)*
          - [addresses-list-template](/app/views/common_templates/_search_results_template.html.erb)
            - *(same structure as player-infos-list-template)*
        - [category_panel_trackers](/app/views/masters/_search_results_category_panel.html.erb)
          - [tracker-histories-list-template](/app/views/common_templates/_search_results_template.html.erb)
            - *(same common_template_list structure)*
        - [category_panel_activity_logs](/app/views/masters/_search_results_category_panel.html.erb)
          - [activity-log-player-contact-phones-list-template](/app/views/common_templates/_search_results_template.html.erb)
          - [activity-log-player-contact-emails-list-template](/app/views/common_templates/_search_results_template.html.erb)
          - [[dynamic-activity-log-type]-list-template](/app/views/common_templates/_search_results_template.html.erb)
            - [common_template_list](/app/views/common_templates/_common_template_list.html.erb)
              - [activity-log-[type]-result-template](/app/views/common_templates/_search_results_template.html.erb)
                - [common_template_result](/app/views/common_templates/_common_template_result.html.erb)
                  - [activity_log_references](/app/views/common_templates/_common_template_result.html.erb)
                    - [dynamic-model-references-list-template](/app/views/common_templates/_search_results_template.html.erb)
                      - [dynamic-model-[name]-result-template](/app/views/common_templates/_search_results_template.html.erb)
                    - [model_reference_button_container](/app/views/common_templates/_common_template_result.html.erb)
                  - *(standard result structure)*
        - [category_panel_external_ids](/app/views/masters/_search_results_category_panel.html.erb)
          - [sage-assignments-list-template](/app/views/external_identifiers/_search_results_template.html.erb)
          - [scantron-assignments-list-template](/app/views/external_identifiers/_search_results_template.html.erb)
          - [[external-id-type]-assignments-list-template](/app/views/external_identifiers/_search_results_template.html.erb)
            - *(same common_template_list structure)*
        - [category_panel_dynamic_models](/app/views/masters/_search_results_category_panel.html.erb)
          - [dynamic-model-[name]-list-template](/app/views/common_templates/_search_results_template.html.erb)
            - [common_template_list](/app/views/common_templates/_common_template_list.html.erb)
              - [dynamic-model-[name]-result-template](/app/views/common_templates/_search_results_template.html.erb)
                - [common_template_result](/app/views/common_templates/_common_template_result.html.erb)
                  - [model_references_list_container](/app/views/common_templates/_common_template_result.html.erb)
                    - [model-references-list-template](/app/views/common_templates/_search_results_template.html.erb)
                  - *(standard result fields)*
    - [master_panel_footer](/app/views/masters/_search_results_master_tabs.html.erb)
      - [master_created_info](/app/views/masters/_search_results_master_tabs.html.erb)

## Key Template Categories

### Core Infrastructure Templates

- **search-results-template**: Root template handling master record iteration
- **common_template_list**: Generic list handler for all collection types  
- **common_template_result**: Generic individual item renderer
- **common_template_result_inner**: Core item structure with fields and metadata

### Master Record Structure

- **master_panel_heading**: Master record header with ID and basic info
- **master_main**: Main content area with tabbed interface
- **master_tabs**: Navigation tabs based on page layout configuration

### Category Panels (based on page layout)

- **category_panel_details**: Core participant info (player_info, contacts, addresses)
- **category_panel_trackers**: Tracker history and status
- **category_panel_activity_logs**: Process workflows and case management
- **category_panel_external_ids**: Real-world identifier systems
- **category_panel_dynamic_models**: Runtime-generated data structures

### Dynamic Templates (generated per configuration)

- **[model-name]-list-template**: Collection view for each model type
- **[model-name]-result-template**: Individual item view for each model type
- **activity-log-[type]-result-template**: Specific activity log type renderers

### Interactive Components

- **edit_item_button**: Edit mode toggle
- **rank_button**: Record ranking/priority
- **activity_log_common_template_show_button**: Activity log navigation
- **model_reference_button_container**: Cross-model relationship buttons

### Field Rendering

- **common_template_result_fields**: Field collection iterator
- **common_template_result_field**: Individual field with label and value
- **field_value_substitution**: Tag substitution for field values
- **update_metadata**: Created/updated timestamps and user info

The template system uses Handlebars partials extensively, with {{> template_name}} calls creating the hierarchical structure. Each level can access parent context data and apply ReStructure-specific filters for user access controls, field visibility rules, and tag substitutions.

## Template state, versions and the skeleton cache

The master skeleton (served from `/pages/<token>/template` and fragment cached under `master_templates_skeleton_cache_key`) only changes for **structural** edits. A purely configuration edit to a dynamic model, activity log or external identifier (labels, captions, field options, `show_if`) is delivered lazily instead:

- Each definition has a `template_version_token`. Its state is emitted as `_fpa.state.template_config.<name>.v<token>`, with a `v0` alias that list templates read.
- When a data response reports a `vdef_version` whose slot is missing, `_fpa.prepare_template_configs` fetches `template_config` for one representative record per type, option type and version. Pending requests are keyed by the root record, version and the versions of its embedded items.
- A form (new or edit) installs its own `v<token>` slot and promotes `v0` unless a newer `v0` is already installed. Shared base aliases are promoted only from the definition's default option type. If a form leaves `v0` older than the live slot, for example a form for a non-default option type, the client makes a single reconciling `template_config` fetch.
- Inputs baked into the skeleton are part of its signature: active definitions, the option types, `references` and `embed` structure, reference `caption_before` captions, the default option type's `alt_width_classes`, dynamic model `position`, page layout panels and access timestamps. Changing any of them rebuilds the skeleton.
- Saving a dynamic model, external identifier or YAML config library does not clear the whole Rails cache. Caches that depend on definitions must be keyed by `definition_cache_version_token` or invalidated explicitly, as `Admin::UserAccessControl.resource_names_cache_key` and `Classification::GeneralSelection::InfoBlockCacheKey` are.
