# frozen_string_literal: true

if defined?(Decidim::Initiatives)
  Decidim::Initiatives.configure do |config|
    # Public Setting that defines the similarity minimum value to consider two
    # initiatives similar. Defaults to 0.25.
    config.similarity_threshold = 100
    config.do_not_require_authorization = true
    # Public Setting that defines how many similar initiatives will be shown.
    # Defaults to 5.
    config.similarity_limit = 0

    # Minimum number of committee members required to pass the initiative to
    # technical validation phase. Only applies to initiatives created by
    # individuals.
    config.minimum_committee_members = 0

    # Number of days available to collect supports after an initiative has been
    # published.
    config.default_signature_time_period_length = 12.months

    # Components enabled for a new initiative
    config.default_components = []

    # Print functionality enabled. Allows the user to get
    # a printed version of the initiative from the administration
    # panel.
    config.print_enabled = false

    # Set a service to generate a timestamp on each vote. The
    # attribute is the name of a class whose instances are
    # initialized with a string containing the data to be
    # timestamped and respond to a timestamp method
    config.timestamp_service = "Decidim::Initiatives::UtcTimestamp"

    config.creation_enabled = true
    config.face_to_face_voting_allowed = true
    config.online_voting_allowed = true
  end

  Decidim.resource_registry.find(:initiatives_type).actions += ["create"]

  Decidim::Initiatives::Engine.routes do
    resources :initiatives, param: :slug, only: [:index, :show, :edit, :update], path: "initiatives" do
      resources :initiative_signatures

      member do
        get :authorization_create_modal, to: "authorization_create_modals#show"
      end
    end
  end

  Decidim::Initiatives::AdminEngine.routes do
    resources :initiatives_settings, only: [:edit, :update], controller: "initiatives_settings"
  end

  Decidim.menu :admin_initiatives_menu do |menu|
    menu.add_item :initiatives_settings,
                  I18n.t("menu.initiatives_settings", scope: "decidim.admin"),
                  decidim_admin_initiatives.edit_initiatives_setting_path(
                    Decidim::InitiativesSettings.find_or_create_by!(
                      organization: current_organization
                    )
                  ),
                  active: is_active_link?(
                    decidim_admin_initiatives.edit_initiatives_setting_path(
                      Decidim::InitiativesSettings.find_or_create_by!(organization: current_organization)
                    )
                  ),
                  if: allowed_to?(:update, :initiatives_settings)
  end
end
