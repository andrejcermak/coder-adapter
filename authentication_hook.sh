export OS_INTERFACE="public"
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_TYPE="v3oidcaccesstoken"
export OS_AUTH_URL=https://identity.brno.openstack.cloud.e-infra.cz/v3
export OS_IDENTITY_PROVIDER="login.e-infra.cz"
export OS_PROTOCOL="openid"
export OS_PROJECT_DOMAIN_ID="3b5cb406d60249508d0ddab2a80502b5"
export OS_ACCESS_TOKEN=$OOD_OIDC_ACCESS_TOKEN
export project_json=$(openstack project list -f json)

CREDENTIALS_FILE="/home/$USER/application_credentials.json"
PROJECTS_FILE="/home/$USER/projects.json"

if [! -f "$PROJECTS_FILE" ]; then
  projects=$(echo "$project_json" | jq '[.[] | {name: .Name, id: .ID}]')
  echo "$projects" | jq '.' > "$PROJECTS_FILE"
  chown $USER $PROJECTS_FILE
  echo "Project list has been created and saved to $PROJECTS_FILE"
fi

if [! -f "$CREDENTIALS_FILE" ]; then
  credentials=()
  for project in $(echo "${project_json}" | jq -r '.[] | @base64'); do
      _jq() {
          echo ${project} | base64 --decode | jq -r ${1}
      }

      project_id=$(_jq '.ID')
      project_name=$(_jq '.Name')
      export OS_PROJECT_ID=$project_id
      # Create application credential
      app_cred=$(openstack application credential create "ood_app_cred_${project_id}" --description "Credentials for ${project_name}" --role member  --role creator  --role load-balancer_member  --role reader -f json)

      # Extract necessary fields
      cred_id=$(echo $app_cred | jq -r '.id')
      cred_secret=$(echo $app_cred | jq -r '.secret')
      cred_name=$(echo $app_cred | jq -r '.name')

      # Append to credentials array
      credentials+=("{\"id\": \"${cred_id}\", \"secret\": \"${cred_secret}\", \"name\": \"${cred_name}\", \"project_id\": \"${project_id}\"}")
  done
  credentials_json=$(printf ",%s" "${credentials[@]}")
  credentials_json="[${credentials_json:1}]"

  echo "$credentials_json" | jq '.' > "$CREDENTIALS_FILE"
  chown $USER $CREDENTIALS_FILE
  echo "Application credentials have been created and saved to $CREDENTIALS_FILE"
fi

                                                                                                           