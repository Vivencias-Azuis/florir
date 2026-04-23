class FamilyMagicLinkJob < ApplicationJob
  queue_as :default

  def perform(family_access_id)
    access = FamilyAccess.find(family_access_id)
    FlorirMailer.magic_link(access).deliver_now
  end
end
