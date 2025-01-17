# frozen_string_literal: true

module Decidim
  module Verifications
    # A command to authorize a user with an authorization handler.
    class AuthorizeUser < Rectify::Command
      # Public: Initializes the command.
      #
      # handler - An AuthorizationHandler object.
      # rubocop:disable Lint/MissingSuper
      def initialize(handler, organization)
        @handler = handler
        @organization = organization
      end
      # rubocop:enable Lint/MissingSuper

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the handler wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        if handler.invalid?
          conflict = create_verification_conflict
          notify_admins(conflict) if conflict.present?

          return broadcast(:invalid)
        end

        Authorization.create_or_update_from(handler)
        duplicates_metadata_in_user!(handler)
        broadcast(:ok)
      end

      private

      attr_reader :handler

      def notify_admins(conflict)
        Decidim::EventsManager.publish(
          event: "decidim.events.verifications.managed_user_error_event",
          event_class: Decidim::Verifications::ManagedUserErrorEvent,
          resource: conflict,
          affected_users: Decidim::User.where(admin: true, organization: @organization)
        )
      end

      def create_verification_conflict
        authorization = Decidim::Authorization.find_by(unique_id: handler.unique_id)
        return if authorization.blank?

        conflict = Decidim::Verifications::Conflict.find_or_initialize_by(
          current_user: handler.user,
          managed_user: authorization.user,
          unique_id: handler.unique_id
        )

        conflict.update(times: conflict.times + 1)

        conflict
      end

      def duplicates_metadata_in_user!(handler)
        return unless handler.class.name == "ExtendedSocioDemographicAuthorizationHandler"

        handler_extended_data = handler.metadata.deep_transform_keys { |k| "socio_#{k}" }
        handler.user.update!(extended_data: handler.user.extended_data.merge(handler_extended_data))
      end
    end
  end
end
