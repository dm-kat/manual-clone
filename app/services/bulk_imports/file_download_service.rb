# frozen_string_literal: true

# File Download Service allows remote file download into tmp directory.
#
# @param configuration [BulkImports::Configuration] Config object containing url and access token
# @param relative_url [String] Relative URL to download the file from
# @param tmpdir [String] Temp directory to store downloaded file to. Must be located under `Dir.tmpdir`.
# @param file_size_limit [Integer] Maximum allowed file size
# @param allowed_content_types [Array<String>] Allowed file content types
# @param filename [String] Name of the file to download, if known. Use remote filename if none given.
module BulkImports
  class FileDownloadService
    ServiceError = Class.new(StandardError)

    REMOTE_FILENAME_PATTERN = %r{filename="(?<filename>[^"]+)"}.freeze
    FILENAME_SIZE_LIMIT = 255 # chars before the extension
    DEFAULT_FILE_SIZE_LIMIT = 5.gigabytes
    DEFAULT_ALLOWED_CONTENT_TYPES = %w(application/gzip application/octet-stream).freeze

    def initialize(
      configuration:,
      relative_url:,
      tmpdir:,
      file_size_limit: DEFAULT_FILE_SIZE_LIMIT,
      allowed_content_types: DEFAULT_ALLOWED_CONTENT_TYPES,
      filename: nil)
      @configuration = configuration
      @relative_url = relative_url
      @filename = filename
      @tmpdir = tmpdir
      @file_size_limit = file_size_limit
      @allowed_content_types = allowed_content_types
    end

    def execute
      validate_tmpdir
      validate_filepath
      validate_url
      validate_content_type
      validate_content_length

      download_file

      validate_symlink

      filepath
    end

    private

    attr_reader :configuration, :relative_url, :tmpdir, :file_size_limit, :allowed_content_types

    def download_file
      File.open(filepath, 'wb') do |file|
        bytes_downloaded = 0

        http_client.stream(relative_url) do |chunk|
          next if bytes_downloaded == 0 && [301, 302, 303, 307, 308].include?(chunk.code)

          bytes_downloaded += chunk.size

          validate_size!(bytes_downloaded)

          if chunk.code == 200
            file.write(chunk)
          else
            raise(ServiceError, "File download error #{chunk.code}")
          end
        end
      end
    rescue StandardError => e
      File.delete(filepath) if File.exist?(filepath)

      raise e
    end

    def http_client
      @http_client ||= BulkImports::Clients::HTTP.new(
        url: configuration.url,
        token: configuration.access_token
      )
    end

    def allow_local_requests?
      ::Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def headers
      @headers ||= http_client.head(relative_url).headers
    end

    def validate_filepath
      Gitlab::Utils.check_path_traversal!(filepath)
    end

    def validate_tmpdir
      Gitlab::Utils.check_allowed_absolute_path!(tmpdir, [Dir.tmpdir])
    end

    def validate_symlink
      if File.lstat(filepath).symlink?
        File.delete(filepath)

        raise(ServiceError, 'Invalid downloaded file')
      end
    end

    def validate_url
      ::Gitlab::UrlBlocker.validate!(
        http_client.resource_url(relative_url),
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        schemes: %w(http https)
      )
    end

    def validate_content_length
      validate_size!(headers['content-length'])
    end

    def validate_size!(size)
      if size.blank?
        raise ServiceError, 'Missing content-length header'
      elsif size.to_i > file_size_limit
        raise ServiceError, "File size %{size} exceeds limit of %{limit}" % {
          size: ActiveSupport::NumberHelper.number_to_human_size(size),
          limit: ActiveSupport::NumberHelper.number_to_human_size(file_size_limit)
        }
      end
    end

    def validate_content_type
      content_type = headers['content-type']

      raise(ServiceError, 'Invalid content type') if content_type.blank? || allowed_content_types.exclude?(content_type)
    end

    def filepath
      @filepath ||= File.join(@tmpdir, filename)
    end

    def filename
      @filename.presence || remote_filename
    end

    # Fetch the remote filename information from the request content-disposition header
    # - Raises if the filename does not exist
    # - If the filename is longer then 255 chars truncate it
    #   to be a total of 255 chars (with the extension)
    def remote_filename
      @remote_filename ||=
        headers['content-disposition'].to_s
        .match(REMOTE_FILENAME_PATTERN)               # matches the filename pattern
        .then { |match| match&.named_captures || {} } # ensures the match is a hash
        .fetch('filename')                            # fetches the 'filename' key or raise KeyError
        .then(&File.method(:basename))                # Ensures to remove path from the filename (../ for instance)
        .then(&method(:ensure_filename_size))         # Ensures the filename is within the FILENAME_SIZE_LIMIT
    rescue KeyError
      raise ServiceError, 'Remote filename not provided in content-disposition header'
    end

    def ensure_filename_size(filename)
      if filename.length <= FILENAME_SIZE_LIMIT
        filename
      else
        extname = File.extname(filename)
        basename = File.basename(filename, extname)[0, FILENAME_SIZE_LIMIT]

        "#{basename}#{extname}"
      end
    end
  end
end
