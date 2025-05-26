import requests
import os
import sys
from collections import defaultdict

# Config
HOSTNAME = os.getenv("HOSTNAME", "tsb.tfc.dogfood.sandbox.tetrate.io")
ORG = os.getenv("ORG", "tfc")
TSB_TOKEN = os.getenv("TSB_TOKEN")

if not TSB_TOKEN:
    print("Missing TSB_TOKEN environment variable", file=sys.stderr)
    sys.exit(1)

# Fetch JSON
url = f"https://{HOSTNAME}/v2/organizations/{ORG}/clusters"
headers = {
    "Authorization": f"Bearer {TSB_TOKEN}"
}

response = requests.get(url, headers=headers, verify=False)
response.raise_for_status()
data = response.json()

# Count per (cluster, state)
counts = defaultdict(int)

# Count per state (summary)
state_totals = defaultdict(int)

for cluster in data.get("clusters", []):
    cluster_name = cluster.get("fqn", "")
    for ns in cluster.get("namespaces", []):
        for svc in ns.get("services", []):
            if svc.get("gatewayHost") is True:
                continue
            state = svc.get("state")
            if state:
                counts[(cluster_name, state)] += 1
                state_totals[state] += 1

# Prepare rows
rows = [(cluster, state, count) for (cluster, state), count in sorted(counts.items())]

# Determine column widths
max_cluster_len = max((len(cluster) for cluster, _, _ in rows), default=7)
max_state_len = max((len(state) for _, state, _ in rows), default=5)

# Print per-cluster counts
print(f"{'Cluster'.ljust(max_cluster_len)}  {'State'.ljust(max_state_len)}  Count")
for cluster, state, count in rows:
    print(f"{cluster.ljust(max_cluster_len)}  {state.ljust(max_state_len)}  {count}")

# Print totals
print("\nSummary:")
print(f"{'State'.ljust(max_state_len)}  Count")
for state, total in sorted(state_totals.items()):
    print(f"{state.ljust(max_state_len)}  {total}")