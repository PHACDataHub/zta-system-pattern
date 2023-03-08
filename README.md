# Zero Trust Architecture Pattern

This is pathfinder project that is aiming to establish the first (but not only) architectural pattern for PHAC systems.
All code embeds opinions and this code is no different. What you see here is opinionated take on ZT (at least at the system level), that is optimizing for high levels of security, compatibility with TBS policy and low operational burden.

*Prominent disclaimer*: this is exploratory work and not yet fit for real world usage. Much of it does't work right yet, but it's useful to drive architectural and security discussions.

TODO:
* Fix hardcode IP in kustomization.yaml
* Debug why the helloworld service isn't reachable with curl

## Dependencies

You'll need a few different tools available in your path for this to work.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [gcloud](https://cloud.google.com/sdk/docs/install)
* [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) or you might be able to get by with `kubectl kustomize`.
* [asmcli](https://cloud.google.com/service-mesh/docs/unified-install/install-dependent-tools#download_asmcli) or use [this](https://aur.archlinux.org/packages/asmcli) if you're on Archlinux.
* make (its probably pre-installed)

## Trying it

At the moment this is driven by a makefile in the root of the project. 
You'll need to update the variables like `project` at the top of the `Makefile` to work for your project, but afterwards you can get a "working" cluster with the following commands:

```sh
# One time project setup:
# Enable the needed services
make enabled
# Reserve an ip for use by the ingress gateway
make ip

# Cluster setup:
# Create a GKE autopilot cluster
make cluster
# Add the cluster to an Anthos Fleet
make fleet
# install the base Anthos Service Mesh (requires asmcli)
make asm
# Install our "hello world" example app and the config for Istio
# (N.B.: update kustomization.yaml to add the ip you created earlier)
make apply
```
