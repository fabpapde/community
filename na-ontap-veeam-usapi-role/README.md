# Veeam USAPI REST Role for NetApp ONTAP (FAS/AFF)

These two Ansible playbooks create a REST access-control role and an associated login user on a NetApp ONTAP cluster, or remove both again. They are required for the Veeam NetApp ONTAP USAPI Plug-In integration.

## Included Files

- **create_veeam_usapi_rest_role.yaml** – creates the role and the login user, including verification
- **delete_veeam_usapi_rest_role.yaml** – removes the login user and the role again (teardown)

## Requirements

- Ansible is installed
- The NetApp collection is installed:
  ```bash
  ansible-galaxy collection install netapp.ontap
  ```
- An ONTAP admin account with sufficient rights to create/remove roles and logins (e.g. cluster admin)
- The Python library `requests` must be installed in the Python interpreter used by Ansible

## No Inventory Required

Both playbooks run against `localhost` (`connection: local`) and take the cluster hostname/username as extra vars — a separate Ansible inventory is not required.

## Before Running

Replace the `<username>` placeholder in the commands below with the actual ONTAP admin username before executing either playbook. The same applies to `<cluster-hostname-or-ip>` — both placeholders must be adjusted to match your environment.

## Password Handling

The ONTAP admin password (and, when creating, the password for the new login user) is prompted for interactively and is never written to the playbook, the shell history, or the Ansible log. The corresponding task when creating the user is additionally protected with `no_log: true`.

## Usage

### Create Role and User

```bash
ansible-playbook create_veeam_usapi_rest_role.yaml \
  -e "netapp_hostname=<cluster-hostname-or-ip>" \
  -e "netapp_username=<username>"
```

You will be prompted for two passwords: the ONTAP admin password and the password for the new login user.

### Remove Role and User

```bash
ansible-playbook delete_veeam_usapi_rest_role.yaml \
  -e "netapp_hostname=<cluster-hostname-or-ip>" \
  -e "netapp_username=<username>"
```

Only the ONTAP admin password is prompted for here, since nothing new is being created.

## What Happens on Create

1. **Create role** – creates a REST role with all required API endpoints and the matching access level (`readonly`, `read_create`, `all`)
2. **Create login user** – creates a login with application `http`, authentication method `password`, linked to the previously created role
3. **Verification** – re-queries the created role including all privileges via REST and displays it (equivalent to `security login rest-role show`)

Both steps (role, user) are idempotent — running the playbook again makes no changes if both already exist exactly as specified.

## What Happens on Teardown

1. **Remove login user**
2. **Remove role**

This order is deliberate, since ONTAP will not allow deleting a role while a user is still assigned to it.

## Permission Overview (Role `veeam-usapi-rest-role`)

| API Endpoint | Access Level |
|---|---|
| `/api/cluster` | readonly |
| `/api/cluster/jobs` | readonly |
| `/api/cluster/licensing/access-tokens` | read_create |
| `/api/cluster/licensing/licenses` | readonly (cluster level only) |
| `/api/cluster/metrocluster` | readonly (cluster level only)  |
| `/api/cluster/nodes` | readonly (cluster level only)  |
| `/api/cluster/peers` | read_create |
| `/api/network/ip/interfaces` | readonly |
| `/api/protocols/nfs/export-policies` | all |
| `/api/protocols/nfs/services` | readonly |
| `/api/protocols/san/fcp/services` | readonly |
| `/api/protocols/san/igroups` | all |
| `/api/protocols/san/iscsi/services` | readonly |
| `/api/protocols/san/lun-maps` | all |
| `/api/snapmirror/relationships` | all |
| `/api/storage/aggregates` | readonly |
| `/api/storage/luns` | all |
| `/api/storage/qtrees` | all |
| `/api/storage/snaplock/compliance-clocks` | readonly |
| `/api/storage/volumes` | all |
| `/api/svm/svms` | readonly |

## Alternative: Manual Creation via ONTAP CLI

If you prefer not to use Ansible, the same role and user can be created directly on the ONTAP CLI:

```bash
# Create Veeam USAPI role:
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/cluster
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/cluster/jobs
security login rest-role create -role veeam-usapi-rest-role -access read_create -api /api/cluster/licensing/access-tokens
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/cluster/licensing/licenses
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/cluster/metrocluster
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/cluster/nodes
security login rest-role create -role veeam-usapi-rest-role -access read_create -api /api/cluster/peers
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/network/ip/interfaces
security login rest-role create -role veeam-usapi-rest-role -access all -api /api/protocols/nfs/export-policies
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/protocols/nfs/services
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/protocols/san/fcp/services
security login rest-role create -role veeam-usapi-rest-role -access all -api /api/protocols/san/igroups
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/protocols/san/iscsi/services
security login rest-role create -role veeam-usapi-rest-role -access all -api /api/protocols/san/lun-maps
security login rest-role create -role veeam-usapi-rest-role -access all -api /api/snapmirror/relationships
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/storage/aggregates
security login rest-role create -role veeam-usapi-rest-role -access all -api /api/storage/luns
security login rest-role create -role veeam-usapi-rest-role -access all -api /api/storage/qtrees
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/storage/snaplock/compliance-clocks
security login rest-role create -role veeam-usapi-rest-role -access all -api /api/storage/volumes
security login rest-role create -role veeam-usapi-rest-role -access readonly -api /api/svm/svms

# Show the security role:
security login rest-role show -role veeam-usapi-rest-role
security login rest-role show -role veeam-usapi-rest-role -instance

# Create the user and assign the security role:
security login create -user-or-group-name <username> -application http -authentication-method password -role veeam-usapi-rest-role

# Show the user:
security login show -user-or-group-name <username>
security login show -user-or-group-name <username> -instance
```

Replace `<username>` with the actual login name you want to create.

## Customization

- **Change role name/username:** adjust `role_name` or `login_user_name` in the `vars` of the respective playbook
- **Additional/different API endpoints:** extend or remove entries in the `role_privileges` list in `create_veeam_usapi_rest_role.yaml`
- **Different application (e.g. `ontapi` instead of `http`):** adjust the `applications` value in the respective user task
