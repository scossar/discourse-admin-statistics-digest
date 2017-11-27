# require_relative '../mailers/report_mailer'

module ::Jobs
  class AdminStatisticsDigest < ::Jobs::Scheduled
    every 1.minutes
    sidekiq_options 'retry' => true, 'queue' => 'critical'

    def execute(opts = nil)
      return unless DateTime.now.day == 1

      ::AdminStatisticsDigest::ReportMailer.digest(30.days.ago.to_date, Date.today).deliver_now
    end
  end
end
