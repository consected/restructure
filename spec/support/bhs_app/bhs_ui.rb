# frozen_string_literal: true

module BhsUi
  AppShortName = 'bhs'
  AppName = 'Brain Health Study'
  CreateSubjectRecord = 'Create Subject Record'
  BhsIdField = 'Bhs'
  NewSubjectCreateButton = 'Create'
  SearchPlayer = 'Search BHS Player'
  SearchButton = 'search'
  # All tabs to be shown in a master record, based on there being no master Page Layout defined for the app
  TabNames = ['details', 'external ids', 'extended info', 'bhs tracker'].freeze
  # The tabs to be shown as expanded by default
  DefaultTabs = ['details', 'bhs tracker'].freeze
end
