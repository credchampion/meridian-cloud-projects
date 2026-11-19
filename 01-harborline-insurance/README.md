# Project 1 – Harborline Insurance: Claims Document Intake (HARB-101)

Event-driven, serverless document intake for an auto & home insurer, built on Azure with Terraform.

## Problem
Customers emailed claim documents to a shared inbox. Staff downloaded and filed them by hand, so documents were lost and there was no audit trail.

## Solution
~~~
Upload ─► Blob Storage (private) ─► Event Grid (BlobCreated) ─► Azure Function (Python) ─► Table Storage (claimlog)
                                                                        │
                                                       Application Insights + Log Analytics
~~~
Files are uploaded under a claim-number folder (e.g. `CLM-10023/photo.jpg`). Within seconds, a function records the claim number, file name, type, size and upload time in the `claimlog` table, partitioned by claim number for fast lookup.

## Requirements → design
| Requirement | Implementation |
|---|---|
| Encrypted at rest & in transit | Storage encryption (default), HTTPS-only, TLS 1.2 minimum |
| No public links | Anonymous blob access disabled (validated: returns `PublicAccessNotPermitted`) |
| US-only data | South Central US region |
| Logged within 1 minute | Event Grid trigger instead of polling blob trigger |
| Handles 10× storm spikes | Flex Consumption plan, capped at 40 instances for cost control |
| Recover accidental deletes | Blob soft delete (7 days) |
| Audit trail | Application Insights backed by Log Analytics |
| Cost tracking | Tags on every resource: `project`, `env`, `owner`, `managed_by` |

## Repository layout
~~~
01-harborline-insurance/
├── function/            # Python Azure Function (event_grid_trigger -> table_output)
└── terraform/
    ├── main.tf          # provider, variables, resource group, claims storage
    ├── functions.tf     # function app, plan, monitoring, claimlog table
    ├── events.tf        # Event Grid subscription (applied after code deploy)
    └── backend.tf       # remote state in Azure Storage (locking + versioning)
~~~

## Deploy
~~~bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
cd terraform && terraform init
terraform plan -out=tfplan && terraform apply tfplan
cd ../function && func azure functionapp publish func-harborline-claims-stg-01 --python
~~~
Note: on a brand-new environment, deploy the function code before the Event Grid subscription can be created (it validates that the function exists).

## Test
~~~bash
az storage blob upload --account-name stharborlineclaimsstg01 -c claims-uploads -n CLM-20001/report.txt -f report.txt
az storage entity query -t claimlog --account-name stharborlineclaimsstg01 -o table
~~~

## Operations practiced
- **Drift:** detected a manual change enabling public access with `terraform plan`, then reverted it
- **Lost state:** removed a resource from state and recovered it with `terraform import`
- **Stuck lock:** diagnosed a locked state blob and released the lease
- **Perpetual diff:** pinned Azure default values to keep plans clean

## Next improvements (production)
- Managed Identity instead of storage connection strings
- Private endpoints / network restrictions
- Lifecycle policy: Cool -> Archive, delete after 7 years
- CI/CD pipeline (GitHub Actions) for plan/apply with approvals
- ZRS/GRS redundancy for production

## Clean up
~~~bash
terraform destroy
~~~
