require 'set'
require 'pathname'

module Airbrake
  # Integration for Phusion Passenger
  module Passenger
    IntegrationException = Class.new(::Exception)
    class << self
      def version
        unless defined?(::PhusionPassenger)
          raise IntegrationException, "PhusionPassenger not detected"
        end
        @version = Gem::Version.new(::PhusionPassenger::VERSION_STRING)
      end

      def version_matches?(req)
        reqs = req.split(',').map(&:strip).compact
        Gem::Requirement.new(*reqs).satisfied_by?(version)
      end

      def integrations
        @integrations ||= begin
          Pathname.new(__FILE__).dirname.each_child do |child|
            next if child == Pathname.new(__FILE__)
            next unless child.file? && child.readable?
            next unless child.fnmatch?('*.rb')
            require "airbrake/passenger/#{child.basename '.rb'}"
          end
          constants.map { |c| const_get(c) }.select do |i|
            i.is_a?(Module) && i.respond_to?(:integrate!)
          end
        end
      end

      def integration
        return @integration if defined?(@integration)
        @integration = integrations.to_a.detect do |i|
          Array[i::VERSION_REQUIREMENT].any? do |vr|
            version_matches?(vr)
          end
        end
        raise IntegrationException, "Your version of PhusionPassenger " \
          "is not currently supported by the airbrake gem." if @integration.nil?
        @integration
      end

      def integrate!
        return @integrated if defined?(@integrated)
        integration.integrate!
      rescue IntegrationException => e
        Kernel.warn e
        @integrated = false
      else
        @integrated = true
      end
    end
  end
end

Airbrake::Passenger.integrate!
