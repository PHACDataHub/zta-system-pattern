# Zero Trust Architecture Pattern

This is pathfinder project that is aiming to establish the first (but not only) architectural pattern for PHAC systems.
All code embeds opinions and this code is no different. What you see here is opinionated take on ZT (at least at the system level), that is optimizing for high levels of security, compatibility with TBS policy and low operational burden.

*Prominent disclaimer*: this is exploratory work and not yet fit for real world usage. Much of it does't work right yet, but it's useful to drive architectural and security discussions.

TODO:
* Fix hardcode IP in kustomization.yaml
* Debug why the helloworld service isn't reachable with curl


## Trying it

At the moment this is driven by a makefile in the root of the project. 
You'll need to update the variables like `project` at the top of the `Makefile` to work for your project, but afterwards you can get a "working" cluster with the following commands:

```sh
# Enable the needed services
make enabled
# Reserve an ip for use by the ingress gateway
make ip
# Create a GKE autopilot cluster
make cluster
# Add the cluster to an Anthos Fleet
make fleet
# Apply the Kubernetes config to the cluster with kustomize 
# (N.B.: update kustomization.yaml to add the ip you created earlier)
make apply
```
