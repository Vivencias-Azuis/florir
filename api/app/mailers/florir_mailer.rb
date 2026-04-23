class FlorirMailer < ApplicationMailer
  default from: "noreply@florir.app"

  def magic_link(family_access)
    @access = family_access
    @patient = family_access.patient
    @url = "#{ENV.fetch("FRONTEND_URL", "http://localhost:3001")}/familia/#{@access.access_token}/progresso"
    mail(to: family_access.user.email,
         subject: "Acesse o progresso de #{@patient.name} — Florir")
  end

  def session_reminder(session)
    @session = session
    @patient = session.patient
    family_emails = @patient.family_accesses.where(active: true).includes(:user).map { |fa| fa.user.email }
    mail(to: family_emails,
         subject: "Lembrete: sessão de #{@patient.name} amanhã — Florir")
  end
end
