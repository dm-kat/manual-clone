# frozen_string_literal: true

module API
  module Helpers
    module PackagesManagerClientsHelpers
      extend Grape::API::Helpers
      include ::API::Helpers::PackagesHelpers

      params :workhorse_upload_params do
        optional 'file.path', type: String, desc: 'Path to locally stored body (generated by Workhorse)'
        optional 'file.name', type: String, desc: 'Real filename as send in Content-Disposition (generated by Workhorse)'
        optional 'file.type', type: String, desc: 'Real content type as send in Content-Type (generated by Workhorse)'
        optional 'file.size', type: Integer, desc: 'Real size of file (generated by Workhorse)'
        optional 'file.md5', type: String, desc: 'MD5 checksum of the file (generated by Workhorse)'
        optional 'file.sha1', type: String, desc: 'SHA1 checksum of the file (generated by Workhorse)'
        optional 'file.sha256', type: String, desc: 'SHA256 checksum of the file (generated by Workhorse)'
      end

      def find_job_from_http_basic_auth
        return unless request.headers

        token = decode_token

        return unless token

        ::Ci::AuthJobFinder.new(token: token).execute
      end

      def find_deploy_token_from_http_basic_auth
        return unless request.headers

        token = decode_token

        return unless token

        DeployToken.active.find_by_token(token)
      end

      def uploaded_package_file(param_name = :file)
        uploaded_file = UploadedFile.from_params(params, param_name, ::Packages::PackageFileUploader.workhorse_local_upload_path)
        bad_request!('Missing package file!') unless uploaded_file
        uploaded_file
      end

      private

      def decode_token
        encoded_credentials = request.headers['Authorization'].to_s.split('Basic ', 2).second
        Base64.decode64(encoded_credentials || '').split(':', 2).second
      end
    end
  end
end
