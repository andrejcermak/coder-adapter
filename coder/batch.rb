require "ood_core/refinements/hash_extensions"
require "json"

# Utility class for the Kubernetes adapter to interact
# with the Kuberenetes APIs.
class OodCore::Job::Adapters::Coder::Batch
  require_relative "coder_job_info"
  def initialize(config)
    #raise JobAdapterError, config
    @host = config[:host]
    @token = config[:token]
  end
  def method_missing(m, *args, &block)
    # Mocked response
    puts "Called #{m} with #{args.inspect}"
  end
  def get_unscoped_token(username)
    output = `/home/#{username}/openstack.sh`
    if $?.success?
            os_token = output.strip
    else
            raise "Error executing aa OpenStack CLI: #{output}"
    end
    os_token
  end
  def get_rich_parameters(os_token, coder_parameters)
    rich_parameter_values = [
    { name: "token", value: os_token }
    ]
    coder_parameters.each do |key, value| 
      rich_parameter_values << { name: key, value: value }
    end
    rich_parameter_values
  end
  def get_headers(coder_token)
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Coder-Session-Token' => coder_token
    }
  end

  def submit(workspace_name, template_id, template_version_name, oidc_access_token, org_id, coder_parameters)
    endpoint = "https://#{@host}/api/v2/organizations/#{org_id}/members/#{username}/workspaces"
    os_token = get_unscoped_token(username)
    rich_parameter_values = get_rich_parameters(os_token, coder_parameters)
    headers = get_headers(@token)
    body = {
      template_id: template_id,
      template_version_name: template_version_name,
      name: "#{username}-#{workspace_name}-#{rand(2_821_109_907_456).to_s(36)}",
      rich_parameter_values: rich_parameter_values
    }

    resp = api_call('post', endpoint, headers, body)
    resp["id"]
  end
  def delete(id)
    endpoint = "https://#{@host}/api/v2/workspaces/#{id}/builds"
    headers = get_headers(@token)
    body = {
      'orphan' => false,
      'transition' => 'delete'
    }
    res = api_call('post', endpoint, headers, body)
  end
  def info(id)
    endpoint = "https://#{@host}/api/v2/workspaces/#{id}?include_deleted=true"
    headers = get_headers(@token)
    workspace_info_from_json(api_call('get', endpoint, headers))
  end
  def coder_state_to_ood_status(coder_state)
    case coder_state
    when "starting"
      "queued"
    when "failed"
      "suspended"
    when "running"
      "running"
    when "deleted"
      "completed"
    else
      "undetermined"
    end
  end
  def build_coder_job_info(json_data, status)
    floating_ip=json_data["latest_build"]["resources"]
    &.find { |resource| resource["type"] == "openstack_networking_floatingip_associate_v2" }
    &.dig("metadata")
    &.find { |meta| meta["key"] == "floating_ip" }
    &.dig("value") || "no floating ip"
    OodCore::Job::Adapters::Coder::CoderJobInfo.new(**{
      id: json_data["id"],
      job_name: json_data["workspace_name"],
      status: OodCore::Job::Status.new(state: status),
      job_owner: json_data["workspace_owner_name"],
      submission_time: json_data["created_at"],
      dispatch_time: 0,
      wallclock_time: 0,
      ood_connection_info: { host: floating_ip, port: 80 },
      native: floating_ip
  })
  end
  def workspace_info_from_json(json_data)
    state = json_data.dig("latest_build", "status") || json_data.dig("latest_build", "job", "status")
    status = coder_state_to_ood_status(state)
    build_coder_job_info(json_data, status)
  end
  def api_call(method, endpoint, headers, body = nil)
    uri = URI(endpoint)

    case method.downcase
    when 'get'
      request = Net::HTTP::Get.new(uri, headers)
    when 'post'
      request = Net::HTTP::Post.new(uri, headers)
    when 'delete'
      request = Net::HTTP::Delete.new(uri, headers)
    else
      raise ArgumentError, "Invalid HTTP method: #{method}"
    end

    request.body = body.to_json if body

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      raise "HTTP Error: #{response.code} #{response.message}  for request #{endpoint} and body #{body}"
    end
  end
  def username
    @username ||= Etc.getlogin
  end
end

