require_relative '../../../../lib/xdoc/interactors/backup_manager'

module Api::Controllers::Documents
  class Backup
    include Api::Action

    def call(_params)
      result = BackupManager.new(request.query_string).call
      puts "LOG:\n#{result.log}"
      self.body = { status: result.status }.to_json
    end
  end
end
