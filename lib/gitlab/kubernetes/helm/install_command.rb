module Gitlab
  module Kubernetes
    module Helm
      class InstallCommand
        include BaseCommand

        attr_reader :name, :files, :chart, :version, :repository

        def initialize(name:, chart:, files:, version: nil, repository: nil)
          @name = name
          @chart = chart
          @version = version
          @files = files
          @repository = repository
        end

        def generate_script
          super + [
            init_command,
            repository_command,
            script_command
          ].compact.join("\n")
        end

        private

        def init_command
          'helm init --client-only >/dev/null'
        end

        def repository_command
          "helm repo add #{name} #{repository}" if repository
        end

        def script_command
          init_flags = "--name #{name}#{optional_tls_flags}#{optional_version_flag}" \
            " --namespace #{Gitlab::Kubernetes::Helm::NAMESPACE}" \
            " -f /data/helm/#{name}/config/values.yaml"

          "helm install #{chart} #{init_flags} >/dev/null\n"
        end

        def optional_version_flag
          " --version #{version}" if version
        end

        def optional_tls_flags
          return unless files.key?(:'ca.pem')

          " --tls" \
            " --tls-ca-cert #{files_dir}/ca.pem" \
            " --tls-cert #{files_dir}/cert.pem" \
            " --tls-key #{files_dir}/key.pem"
        end
      end
    end
  end
end
