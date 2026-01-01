# Custom sybase_session resource with multi-client support
# Supports both SAP isql and FreeTDS tsql for Sybase connectivity
#
# This resource fixes two issues:
# 1. Local execution "same file" upload error
# 2. Support for tsql (FreeTDS) as alternative to SAP's isql

require "inspec/resources/command"
require "inspec/utils/database_helpers"
require "hashie/mash"
require "csv" unless defined?(CSV)
require "tempfile" unless defined?(Tempfile)

module Inspec::Resources
  class SybaseSessionLocal < Inspec.resource(1)
    name "sybase_session_local"
    supports platform: "unix"
    desc "Use the sybase_session InSpec resource to test commands against a Sybase database"
    example <<~EXAMPLE
      sql = sybase_session(username: 'my_user', password: 'password', server: 'SYBASE', database: 'pubs2')
      describe sql.query("SELECT * FROM authors").row(0).column('au_lname') do
        its('value') { should eq 'Smith' }
      end
    EXAMPLE

    attr_reader :bin, :col_sep, :database, :password, :server, :sybase_home, :username, :client_type

    def initialize(opts = {})
      @username = opts[:username]
      @password = opts[:password]
      @database = opts[:database]
      @server = opts[:server]
      @sybase_home = opts[:sybase_home] || "/opt/sap"
      @col_sep = "|"

      fail_resource "Can't run Sybase checks without authentication" unless username && password
      fail_resource "You must provide a server name for the session" unless server
      fail_resource "You must provide a database name for the session" unless database

      # Auto-detect available client: prefer SAP isql, fall back to tsql
      @bin = opts[:bin]
      @client_type = detect_client_type
      fail_resource "Cannot find Sybase client (isql or tsql)" unless @client_type
    end

    def query(sql)
      sql_file_path = create_sql_file(sql)

      command = build_command(sql_file_path)
      client_cmd = inspec.command(command)

      res = client_cmd.exit_status

      # Clean up temporary file
      cleanup_sql_file(sql_file_path)

      # Handle tsql-specific output (severity 10 messages are informational)
      stdout = client_cmd.stdout
      stderr = client_cmd.stderr

      if @client_type == :tsql
        # tsql returns 0 on success, check for actual errors in output
        if stdout.match?(/Msg\s\d+\s\(severity\s([2-9]\d|1[1-9]|[2-9][0-9])/) || stderr.match?(/Msg\s\d+/)
          skip_resource("tsql error: stdout='#{stdout}', stderr='#{stderr}'")
          return DatabaseHelper::SQLQueryResult.new(client_cmd, [])
        end
        return DatabaseHelper::SQLQueryResult.new(client_cmd, parse_tsql_result(stdout))
      else
        # SAP isql error handling
        unless res == 0
          skip_resource("isql exited with code #{res}: stderr='#{stderr}', stdout='#{stdout}'")
          return DatabaseHelper::SQLQueryResult.new(client_cmd, [])
        end
        unless stderr == ""
          skip_resource("isql error: '#{stderr}', stdout='#{stdout}'")
          return DatabaseHelper::SQLQueryResult.new(client_cmd, [])
        end
        if stdout.match?(/Msg\s\d+,\sLevel\s\d+,\sState\s\d+/)
          skip_resource("isql error in output: #{stdout}")
          return DatabaseHelper::SQLQueryResult.new(client_cmd, [])
        end
        return DatabaseHelper::SQLQueryResult.new(client_cmd, parse_isql_result(stdout))
      end
    end

    def resource_id
      @database || "Sybase Session"
    end

    def to_s
      "Sybase Session (#{@client_type})"
    end

    private

    def detect_client_type
      if @bin
        # User specified a binary - check if it exists
        return :isql if @bin.include?("isql") && inspec.command("which #{@bin}").exit_status == 0
        return :tsql if @bin.include?("tsql") && inspec.command("which #{@bin}").exit_status == 0
        return nil
      end

      # Auto-detect: prefer SAP isql (in SYBASE path), then tsql
      sap_isql = "#{@sybase_home}/OCS-16_0/bin/isql"
      if inspec.command("test -x #{sap_isql}").exit_status == 0
        @bin = sap_isql
        return :isql
      end

      # Check for tsql (FreeTDS)
      if inspec.command("which tsql").exit_status == 0
        @bin = "tsql"
        return :tsql
      end

      nil
    end

    def build_command(sql_file_path)
      if @client_type == :tsql
        # FreeTDS tsql syntax: tsql -S server -U user -P password < file.sql
        "LANG=en_US.UTF-8 #{@bin} -S #{server} -U #{username} -P \"#{password}\" < #{sql_file_path}"
      else
        # SAP isql syntax: isql -S server -U user -D database -P password < file.sql
        "LANG=en_US.UTF-8 SYBASE=#{sybase_home} #{@bin} -s\"#{col_sep}\" -w80000 -S #{server} -U #{username} -D #{database} -P \"#{password}\" < #{sql_file_path}"
      end
    end

    def parse_isql_result(stdout)
      output = stdout.gsub(/\r/, "").strip
      lines = output.lines
      return [] if lines.length < 3

      trimmed_output = ([lines[0]] << lines.slice(2..-3)).join("")
      header_converter = Proc.new do |header|
        if header.match?(/^Default\s+$/)
          "default_value"
        else
          header.downcase.strip
        end
      end
      field_converter = ->(field) { field&.strip }
      CSV.parse(trimmed_output, headers: true, header_converters: header_converter, converters: field_converter, col_sep: col_sep).map { |row| Hashie::Mash.new(row.to_h) }
    end

    def parse_tsql_result(stdout)
      # tsql output format:
      # locale messages...
      # 1> 2>
      # column_value
      # (N row affected)
      output = stdout.gsub(/\r/, "")

      # Remove tsql prompt lines and locale messages
      lines = output.lines.reject do |line|
        line.match?(/^locale\s/) ||
        line.match?(/^using default charset/) ||
        line.match?(/^\d+>\s*$/) ||
        line.match?(/^\(\d+ rows? affected\)/) ||
        line.match?(/^Msg\s\d+\s\(severity\s10/) ||  # Informational messages
        line.strip.empty?
      end

      return [] if lines.empty?

      # Simple result parsing - tsql doesn't have headers like isql
      # Return array of Mash objects with 'value' key for single column results
      lines.map do |line|
        value = line.strip
        Hashie::Mash.new({ "value" => value })
      end
    end

    def local_execution?
      backend_name = inspec.backend.class.name.to_s.downcase
      backend_name.include?("local") || !backend_name.include?("ssh")
    end

    def create_sql_file(sql)
      if local_execution?
        temp_file = Tempfile.new(["sybase_local", ".sql"], "/tmp")
        temp_file.write("#{sql}\n")
        temp_file.write("go\n")
        temp_file.flush
        temp_file.close
        @local_temp_file = temp_file
        temp_file.path
      else
        upload_sql_file(sql)
      end
    end

    def cleanup_sql_file(path)
      if local_execution?
        File.unlink(path) if File.exist?(path)
        @local_temp_file = nil
      else
        rm_cmd = inspec.command("rm #{path}")
        # Log but don't fail on cleanup errors
        Inspec::Log.warn("Unable to delete temporary SQL file at #{path}: #{rm_cmd.stderr}") unless rm_cmd.exit_status == 0
      end
    end

    def upload_sql_file(sql)
      remote_temp_dir = "/tmp"
      local_temp_file = Tempfile.new(["sybase", ".sql"])
      begin
        local_temp_file.write("#{sql}\n")
        local_temp_file.write("go\n")
        local_temp_file.flush
        filename = File.basename(local_temp_file.path)
        remote_file_path = "#{remote_temp_dir}/#{filename}"
        inspec.backend.upload([local_temp_file.path], remote_temp_dir)
      ensure
        local_temp_file.close
        local_temp_file.unlink
      end
      remote_file_path
    end
  end
end
