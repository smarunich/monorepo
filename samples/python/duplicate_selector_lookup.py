import requests
import os
import sys
import json
import argparse
from collections import defaultdict

# Config
HOSTNAME = os.getenv("HOSTNAME", "tsb.tfc.dogfood.sandbox.tetrate.io")
ORG = os.getenv("ORG", "tfc")
TSB_TOKEN = os.getenv("TSB_TOKEN")

if not TSB_TOKEN:
    print("Missing TSB_TOKEN environment variable", file=sys.stderr)
    sys.exit(1)

# Setup session with common headers
session = requests.Session()
session.verify = False
session.headers.update({
    "Authorization": f"Bearer {TSB_TOKEN}",
    "Content-Type": "application/json"
})

def get_tenants():
    """Fetch all tenants in the organization."""
    response = session.get(f"https://{HOSTNAME}/v2/organizations/{ORG}/tenants")
    response.raise_for_status()
    return response.json().get('tenants', [])

def get_workspaces(tenant_fqn):
    """Fetch all workspaces for a given tenant."""
    response = session.get(f"https://{HOSTNAME}/v2/{tenant_fqn}/workspaces")
    response.raise_for_status()
    return response.json().get('workspaces', [])

def read_namespaces_from_file(filename):
    """Read namespaces from a JSON file."""
    try:
        with open(filename, 'r') as f:
            data = json.load(f)
            if not isinstance(data, list):
                print(f"Error: Expected a list of namespaces in {filename}", file=sys.stderr)
                return []
            return data
    except FileNotFoundError:
        print(f"Error: File {filename} not found", file=sys.stderr)
        return []
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in {filename}", file=sys.stderr)
        return []

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Check if namespaces in file are already used in workspaces.')
    parser.add_argument('--file', required=True, type=str, help='Path to a JSON file containing a list of namespaces to check')
    parser.add_argument('--debug', action='store_true', help='Enable debug output')
    args = parser.parse_args()

    # Read namespaces from file
    namespaces_to_check = read_namespaces_from_file(args.file)
    if not namespaces_to_check:
        print("No valid namespaces found in the provided file.")
        return
        
    if args.debug:
        print(f"Namespaces to check: {', '.join(namespaces_to_check)}\n")

    # Dictionary to track which namespaces are in use and where
    namespace_usage = {ns: [] for ns in namespaces_to_check}
    
    try:
        for tenant in get_tenants():
            for workspace in get_workspaces(tenant['fqn']):
                try:
                    workspace_name = workspace['fqn'].split('/')[-1]
                    selectors = workspace.get('namespaceSelector', {})
                    if not selectors:
                        continue
                    if isinstance(selectors, dict) and 'names' in selectors:
                        workspace_namespaces = selectors['names']
                        if args.debug:
                            print(f"Workspace: {workspace_name}")
                            print(f"  Namespaces: {workspace_namespaces}")
                        
                        # Check each namespace in this workspace against our list
                        for ns in workspace_namespaces:
                            if ns in namespace_usage:
                                namespace_usage[ns].append(workspace_name)
                                if args.debug:
                                    print(f"  Namespace '{ns}' is in our list and used by {workspace_name}")
                except Exception as e:
                    print(f"Error processing {workspace['fqn']}: {str(e)}", file=sys.stderr)
        
        # Report which namespaces are already in use
        used_namespaces = {ns: workspaces for ns, workspaces in namespace_usage.items() if workspaces}
        unused_namespaces = [ns for ns in namespace_usage if not namespace_usage[ns]]
        
        if used_namespaces:
            print("\nThe following namespaces are already in use:")
            for ns, workspaces in sorted(used_namespaces.items()):
                print(f"\nNamespace: {ns}")
                print("Used by workspaces:")
                for ws in workspaces:
                    print(f"  - {ws}")
        
        if unused_namespaces:
            print("\nThe following namespaces are not currently in use by any workspace:")
            for ns in sorted(unused_namespaces):
                print(f"  - {ns}")
        
        if not used_namespaces and not unused_namespaces:
            print("\nNo namespaces from the file were found in any workspace.")
            
    except Exception as e:
        print(f"An error occurred: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
