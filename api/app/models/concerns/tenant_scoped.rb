module TenantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :clinic
    default_scope { where(clinic_id: Current.clinic_id) if Current.clinic_id }
  end
end
