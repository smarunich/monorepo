export FOLDER="."

cat >"${FOLDER}/teams_and_users.yaml" <<EOF
---
apiVersion: api.tsb.tetrate.io/v2
kind: Team
metadata:
  displayName: Payroll
  name: Payroll
  organization: cx-nist-demo-org
spec:
  displayName: Payroll
  fqn: organizations/cx-nist-demo-org/teams/Payroll
  members:
  - organizations/cx-nist-demo-org/users/BotA
---
apiVersion: api.tsb.tetrate.io/v2
kind: User
metadata:
  displayName: cn=Andi Bot,ou=Human Resources,dc=tetrate,dc=io
  name: BotA
  organization: cx-nist-demo-org
spec:
  displayName: cn=Andi Bot,ou=Human Resources,dc=tetrate,dc=io
  email: BotA@ns-mail7.com
  fqn: organizations/cx-nist-demo-org/users/BotA
  loginName: BotA
  sourceType: LDAP
EOF

tctl apply -f "${FOLDER}/teams_and_users.yaml"
