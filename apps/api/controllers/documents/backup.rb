require_relative '../../../../lib/xdoc/interactors/backup_manager'

module Api::Controllers::Documents
  class Backup
    include Api::Action

    def call(_params)
      result = BackupManager.new(request.query_string).call
      self.body = { status: result.status,
                    backup_number: result.backup_number,
                    backup_date: result.backup_date,
                    report: result.report,
                    backup_text: result.backup_text
      }.to_json
    end
  end

end
