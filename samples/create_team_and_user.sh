export FOLDER="."

cat >"${FOLDER}/teams_and_users.yaml" <<EOF
---
apiVersion: api.tsb.tetrate.io/v2
kind: Team
metadata:
  displayName: appdevops-team-a
  name: appdevops-team-a
  organization: tetrate
spec:
  displayName: appdevops-team-a
  members:
  - organizations/tetrate/users/BotA
---
apiVersion: api.tsb.tetrate.io/v2
kind: User
metadata:
  displayName: cn=Andi Bot,ou=Human Resources,dc=tetrate,dc=io
  name: BotA
  organization: tetrate
spec:
  displayName: cn=Andi Bot,ou=Human Resources,dc=tetrate,dc=io
  email: BotA@ns-mail7.com
  fqn: organizations/tetrate/users/BotA
  loginName: BotA
  sourceType: LDAP
EOF

tctl apply -f "${FOLDER}/teams_and_users.yaml"

# Define role https://docs.tetrate.io/service-bridge/1.4.x/en-us/refs/tsb/rbac/v2/role#role
cat >"${FOLDER}/sample_role.yaml" <<EOF
---
apiVersion: rbac.tsb.tetrate.io/v2
kind: Role
metadata:
  description: appdevops
  displayName: appdevops
  name: appdevops
spec:
  description: appdevops
  displayName: appdevops
  fqn: rbac/appdevops
  rules:
  - permissions:
    - READ
    - WRITE
    - CREATE
    - DELETE
EOF

tctl apply -f "${FOLDER}/sample_role.yaml"

# Bind the role 
# https://docs.tetrate.io/service-bridge/1.4.x/en-us/refs/tsb/rbac/v2/tenant_access_bindings
# https://docs.tetrate.io/service-bridge/1.4.x/en-us/refs/tsb/rbac/v2/workspace_access_bindings
cat >"${FOLDER}/sample_wab.yaml" <<EOF
apiVersion: rbac.tsb.tetrate.io/v2
kind: WorkspaceAccessBindings
metadata:
  organization: myorg
  tenant: mycompany
  workspace: w1
spec:
  allow:
  - role: rbac/appdevops
    subjects:
    - team: organization/tetrate/teams/appdevops-team-a
EOF
