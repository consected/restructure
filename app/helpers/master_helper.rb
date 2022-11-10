module MasterHelper
  def master_viewables
    return @master_viewables if @master_viewables

    @master_viewables = Admin::UserAccessControl.viewable_tables current_user
    @master_viewables[:pro_infos] &&= !hide_pro_info_tabs?
    @master_viewables
  end

  # get only the viewables marked true
  def true_master_viewables
    @true_master_viewables ||= master_viewables.select { |_k, v| v }.map(&:first)
  end

  def hide_player_tabs?
    @hide_player_tabs ||= app_config_set(:hide_player_tabs) || app_config_set(:hide_participant_tabs)
  end

  def hide_pro_info_tabs?
    app_config_set(:hide_pro_info) || app_config_set(:hide_secondary_info)
  end

  #
  # Render the specified partial, then compress it, returning both original and compressed results
  # @param [String] partial - standard partial name
  # @return [Array] both results [uncompressed partial, compressed value]
  def render_and_compress_partial(partial)
    Rails.logger.info "render_and_compress_partial(#{partial})"
    part = render partial: partial
    comp = ActiveSupport::Gzip.compress(part)

    [part, comp]
  end
end
