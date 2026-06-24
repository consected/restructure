# frozen_string_literal: true

require 'ipaddr'
require 'resolv'

module Utilities
  #
  # Reusable Server-Side Request Forgery (SSRF) guard for any code path that
  # follows an admin- or user-configurable URL out to a remote HTTP service.
  #
  # The default blocked IP ranges and allowed schemes are defined in
  # config/initializers/app_default_settings.rb and surfaced via
  # Settings::BlockedExternalIpRanges and Settings::AllowedExternalUrlSchemes.
  # Per-caller allowlists (e.g. Settings::PullExternalDataAllowedHosts) can be
  # passed via the +allowed_hosts+ option.
  #
  # Example:
  #   uri = Utilities::UrlSafety.safe_parse(
  #     url,
  #     allowed_hosts: Settings::PullExternalDataAllowedHosts,
  #     allow_private: Settings::PullExternalDataAllowPrivateHosts,
  #     context: 'pull_external_data'
  #   )
  #
  class UrlSafety
    class UnsafeUrlError < FphsException; end

    class << self
      #
      # Parse a URL and validate it is safe to request.
      #
      # The URL must:
      # - parse cleanly and use a permitted scheme
      # - have a host
      # - resolve (if a hostname) to addresses that are not in the configured
      #   blocked ranges, unless an explicit allowlist matches the host or
      #   +allow_private+ is true.
      #
      # Hostnames that fail to resolve are permitted to fall through to the
      # underlying HTTP client (which will fail naturally), since refusing them
      # here would break legitimate test stubs and intermittent DNS conditions.
      #
      # @param [String] url
      # @param [Array<String>, nil] allowed_hosts host allowlist (exact match,
      #   case-insensitive). When matched, the private-range check is skipped.
      # @param [Boolean] allow_private if true, skip the private-range check
      # @param [String] context label included in error messages, identifying
      #   the calling subsystem (e.g. 'pull_external_data')
      # @return [URI::Generic]
      # @raise [UnsafeUrlError]
      def safe_parse(url, allowed_hosts: nil, allow_private: false, context: 'external_url')
        uri = URI.parse(url.to_s)

        unless allowed_schemes.include?(uri.scheme)
          raise UnsafeUrlError,
                "#{context} refused URL with unsupported scheme: #{uri.scheme.inspect}"
        end

        host = uri.host
        raise UnsafeUrlError, "#{context} refused URL with no host" if host.blank?

        return uri if host_allowlisted?(host, allowed_hosts)
        return uri if allow_private

        resolve_addresses(host).each do |addr|
          next unless blocked_address?(addr)

          raise UnsafeUrlError,
                "#{context} refused URL resolving to blocked address #{addr} (host=#{host})"
        end

        uri
      rescue URI::InvalidURIError => e
        raise UnsafeUrlError, "#{context} refused invalid URL: #{e.message}"
      end

      #
      # Check whether an address falls within any of the configured blocked
      # ranges. IPv4-mapped IPv6 addresses are unmapped before comparison so
      # attackers cannot bypass IPv4 filters by encoding loopback as
      # ::ffff:127.0.0.1.
      # @param [IPAddr] addr
      # @return [Boolean]
      def blocked_address?(addr)
        candidates = [addr]
        candidates << addr.native if addr.ipv6? && addr.ipv4_mapped?
        candidates.any? { |c| blocked_ip_ranges.any? { |r| r.include?(c) } }
      end

      private

      def allowed_schemes
        Settings::AllowedExternalUrlSchemes
      end

      def blocked_ip_ranges
        Settings::BlockedExternalIpRanges
      end

      def host_allowlisted?(host, allowed_hosts)
        return false if allowed_hosts.blank?

        Array(allowed_hosts).any? { |h| h.to_s.downcase == host.downcase }
      end

      #
      # Resolve a host (which may itself be an IP literal) to the set of
      # addresses that a subsequent connect would reach. DNS failures are
      # treated as "no resolved addresses".
      # @param [String] host
      # @return [Array<IPAddr>]
      def resolve_addresses(host)
        bare = host.delete_prefix('[').delete_suffix(']')
        return [IPAddr.new(bare)] if ip_literal?(bare)

        Resolv.getaddresses(host).filter_map do |a|
          IPAddr.new(a)
        rescue IPAddr::InvalidAddressError
          nil
        end
      rescue Resolv::ResolvError, IPAddr::InvalidAddressError
        []
      end

      def ip_literal?(str)
        IPAddr.new(str)
        true
      rescue IPAddr::InvalidAddressError
        false
      end
    end
  end
end
