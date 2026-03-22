# frozen_string_literal: true

module ControllerUtils
  extend ActiveSupport::Concern

  protected

  def prevent_cache
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def params_nil_if_blank(p)
    p1 = p.dup
    p.each do |k, v|
      if v.is_a? Hash
        p1[k] = params_nil_if_blank v
      elsif v.is_a? Array
        va = v.reject(&:blank?)
        va = nil if va.empty?
        p1[k] = va
      elsif v.blank?
        p1[k] = nil
      end
    end

    p1
  end

  def params_downcase(p)
    p1 = p.dup
    p.each do |k, v|
      if v.is_a? Hash
        p1[k] = params_downcase v
      elsif v.is_a?(String) && !v.blank?
        p1[k] = v.downcase
      end
    end

    p1
  end

  def canceled?
    params[:id] == 'cancel'
  end
end
