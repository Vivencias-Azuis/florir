class SessionReminderJob < ApplicationJob
  queue_as :default

  def perform(session_id)
    session = TherapySession.find(session_id)
    FlorirMailer.session_reminder(session).deliver_now
  end
end
