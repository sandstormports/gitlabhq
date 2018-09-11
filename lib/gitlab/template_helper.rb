module Gitlab
  module TemplateHelper
    include Gitlab::Utils::StrongMemoize

    def prepare_template_environment(file)
      return unless file

      if Gitlab::ImportExport.object_storage?
        params[:import_export_upload] = ImportExportUpload.new(import_file: file)
      else
        FileUtils.mkdir_p(File.dirname(import_upload_path))
        FileUtils.copy_entry(file.path, import_upload_path)

        params[:import_source] = import_upload_path
      end
    end

    def import_upload_path
      strong_memoize(:import_upload_path) do
        Gitlab::ImportExport.import_upload_path(filename: tmp_filename)
      end
    end

    def tmp_filename
      SecureRandom.hex
    end
  end
end
