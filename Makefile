#################################################################################
# GLOBALS                                                                       #
#################################################################################
SHELL := /usr/bin/bash

project := pdcp-cloud-013-zt-pattern
name := zta-system-pattern
ipname := zta-system-pattern-ip
region := northamerica-northeast1
release_channel := regular
subdomain := ztapattern
project_number != gcloud projects describe "$(project)" --format="csv[no-heading,separator=' '](projectNumber)"
ip != gcloud compute addresses describe --region $(region) $(ipname) --format='value(address)'

.PHONY: apply
apply:
		kustomize build | kubectl apply -f -

.PHONY: enabled
enabled:
		gcloud services enable artifactregistry.googleapis.com --project="$(project)"
		gcloud services enable dns.googleapis.com --project="$(project)"
		gcloud services enable anthos.googleapis.com --project="$(project)"
		gcloud services enable meshca.googleapis.com --project="$(project)"
		gcloud services enable mesh.googleapis.com --project="$(project)"
		gcloud services enable container.googleapis.com --project="$(project)"

# Reserve an IP for use by our service mesh gateway.
.PHONY: ip
ip:
		gcloud compute addresses create "$(ipname)" --project=$(project) --region="$(region)"

# Create an autopilot cluster
.PHONY: cluster
cluster:
		gcloud container --project "$(project)" clusters create-auto "$(name)" --region "$(region)" --release-channel "$(release_channel)"

# Register our cluster with the fleet:
# https://cloud.google.com/service-mesh/docs/managed/provision-managed-anthos-service-mesh
.PHONY: fleet
fleet:
		gcloud container fleet mesh enable --project "$(project)"
		gcloud container fleet memberships register "$(name)" --gke-uri=https://container.googleapis.com/v1/projects/"$(project)"/locations/"$(region)"/clusters/"$(name)" --enable-workload-identity --project "$(project)"
		gcloud projects add-iam-policy-binding "$(project)" --member "serviceAccount:service-$(project_number)@gcp-sa-servicemesh.iam.gserviceaccount.com" --role roles/anthosservicemesh.serviceAgent
		gcloud container clusters update  --project "$(project)" "$(name)" --region "$(region)" --update-labels "mesh_id=proj-$(project_number)"
		gcloud container fleet mesh update --management automatic --memberships "$(name)" --project "$(project)"

# Install anthos service mesh aka: asm
.PHONY: asm
asm:
		asmcli install --project_id "$(project)" --fleet_id "$(project)" --cluster_name "$(name)" --cluster_location "$(region)" --output_dir asm --enable_all --ca mesh_ca --managed --use-managed-cni

# Install anthos service mesh aka: asm
.PHONY: print-asm
print-asm:
		asmcli print-config --project_id "$(project)" --fleet_id "$(project)" --cluster_name "$(name)" --cluster_location "$(region)" --output_dir asm --enable_all --ca mesh_ca --managed --use-managed-cni

# This lets us watch the fleet config to see if our cluster is set up correctly. See:
# https://cloud.google.com/service-mesh/docs/managed/provision-managed-anthos-service-mesh#verify_the_control_plane_has_been_provisioned
.PHONY: watch-mesh
watch-mesh:
		watch gcloud container fleet mesh describe --project "$(project)"

# XXX: Commands below here are are work in progress.

# TODO: get dnssec working
# https://www.canada.ca/en/government/system/digital-government/policies-standards/enterprise-it-service-common-configurations/dns.html#cha2
.PHONY: dns
dns:
		gcloud services enable dns.googleapis.com
		gcloud dns --project="$(project)" managed-zones create $(subdomain) --description="" --dns-name="$(subdomain).alpha.canada.ca." --visibility="public" --dnssec-state="off"
		gcloud dns --project="$(project)" record-sets create "$(subdomain).alpha.canada.ca." --zone="$(subdomain)" --type="CAA" --ttl="300" --rrdatas="0 issue "letsencrypt.org""
		gcloud dns --project="$(project)" record-sets create "$(subdomain).alpha.canada.ca." --zone="$(subdomain)" --type="A" --ttl="300" --rrdatas="$(ip)"

# TODO: reduce priviledges below dns admin
# Should only require these dns.resourceRecordSets.*, dns.changes.* and dns.managedZones.list
.PHONY: dns-solver-service-account
dns-solver-service-account:
		gcloud iam service-accounts create dns01-solver --display-name "dns01-solver"
		gcloud projects add-iam-policy-binding "$(project)" --member "serviceAccount:dns01-solver@$(project).iam.gserviceaccount.com" --role roles/dns.admin
		gcloud iam service-accounts add-iam-policy-binding --role roles/iam.workloadIdentityUser --member "serviceAccount:$(project).svc.id.goog[cert-manager/cert-manager]" dns01-solver@$(project).iam.gserviceaccount.com

.ONESHELL:
.PHONY: certmanager
certmanager:
		kustomize build certmanager | kubectl apply -f -

# Seed the cluster with deployment keys so that flux can write back to the GitHub repository.
# TODO: Need to set up encryption keys for secrets too: https://fluxcd.io/flux/guides/mozilla-sops/
.ONESHELL:
.PHONY: deploy-keys
deploy-keys:
		mkdir deploy
		kubectl create namespace flux-system -o yaml --dry-run=client > deploy/namespace.yaml
		ssh-keygen -t ed25519 -q -N "" -C "flux-read-write" -f deploy/identity
		ssh-keyscan github.com > deploy/known_hosts
		@cat <<-'EOF' > deploy/kustomization.yaml
		apiVersion: kustomize.config.k8s.io/v1beta1
		kind: Kustomization
		resources:
		  - namespace.yaml
		secretGenerator:
		- files:
		  - identity
		  - identity.pub
		  - known_hosts
		  name: flux-system
		  namespace: flux-system
		generatorOptions:
		  disableNameSuffixHash: true
		EOF
		@echo "Now add the contents of deploy/identity.pub as a GitHub deploy key."
