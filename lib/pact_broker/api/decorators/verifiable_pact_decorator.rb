require_relative 'base_decorator'
require 'pact_broker/api/pact_broker_urls'
require 'delegate'
require 'pact_broker/pacts/verifiable_pact_messages'

module PactBroker
  module Api
    module Decorators
      class VerifiablePactDecorator < BaseDecorator

        # Allows a "flat" VerifiablePact to look like it has
        # a nested verification_properties object for Reform
        class Reshaper < SimpleDelegator
          def verification_properties
            __getobj__()
          end
        end

        def initialize(verifiable_pact)
          super(Reshaper.new(verifiable_pact))
        end

        property :verification_properties, as: :verificationProperties do
          property :pending,
            if: ->(context) { context[:options][:user_options][:include_pending_status] }
          property :wip, if: -> (context) { context[:represented].wip }
          property :inclusion_reason, as: :inclusionReason, exec_context: :decorator
          property :pending_reason, as: :pendingReason, exec_context: :decorator,
            if: ->(context) { context[:options][:user_options][:include_pending_status] }

          property :notices, getter: -> (context) { context[:decorator].notices(context[:options][:user_options]) }
          property :noteToDevelopers, getter: -> (_) { "Please print out the text from the 'notices' rather than using the inclusionReason and the pendingReason fields. These will be removed when this API moves out of beta."}

          def inclusion_reason
            PactBroker::Pacts::VerifiablePactMessages.new(represented).inclusion_reason
          end

          def pending_reason
            PactBroker::Pacts::VerifiablePactMessages.new(represented).pending_reason
          end

          def notices(user_options)
            mess = [{
              text: inclusion_reason
            }]
            mess << { text: pending_reason } if user_options[:include_pending_status]
            mess
          end
        end

        link :self do | context |
          {
            href: pact_version_url(represented, context[:base_url]),
            name: represented.name
          }
        end
      end
    end
  end
end
