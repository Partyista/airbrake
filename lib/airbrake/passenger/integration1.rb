require 'airbrake/passenger/integrate'

module Airbrake
  module Passenger
    # Implementation of Passenger Integration for Versions 4.0 thru 5.0
    module Integration1
      VERSION_REQUIREMENT = '>= 4.0, < 5.1'.freeze

      class << self
        def integrate!
          ::PhusionPassenger.require_passenger_lib 'loader_shared_helpers'
          ::PhusionPassenger::LoaderSharedHelpers.send :extend, ClassMethods
        end
      end

      # Module to be extended into ::PhusionPassenger::LoaderSharedHelpers
      module ClassMethods
        def self.extended(klass)
          if klass.respond_to?(:about_to_abort)
            klass.send :alias_method, :about_to_abort_without_notifier, :about_to_abort
          end
        end

        def about_to_abort(*args)
          exception = args.last if args.last.is_a?(Exception)
          if exception
            notice = ::Airbrake.build_notice(exception)
            notice[:context][:component] = "PhusionPassenger " \
              "v#{::PhusionPassenger::VERSION_STRING}"
            notice[:context][:action] = 'spawning'
            # TODO: Add more contextual info here(?)
            ::Airbrake.notify_sync(notice)
          end
          return unless respond_to?(:about_to_abort_without_notifier)
          about_to_abort_without_notifier(*args)
        end
      end
    end
  end
end
