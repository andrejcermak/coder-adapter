# coder-adapter
Coder adapter to add OpenStack support in Open OnDemand. Part of my Master thesis

## Prerequisites
1. Running instance of Open OnDemand
2. Running coder environment
3. Have generated API token in coder [https://coder.com/docs/admin/users/sessions-tokens]

## How to use
1. `cd /opt/ood/gems/gems/ood_core-0.25.0/lib/ood_core/job/adapters/`
2. `git clone git@github.com:andrejcermak/coder-adapter.git`
3. Define cluster under `/etc/ood/config/clusters.d` using following .yaml file

## Cluster config
``` yaml
---
v2:
  metadata:
    title: "Openstack via CODER"
  job:
    adapter: "coder"
    host: "your host"
    cluster: "coder"
    token: "your API token"
  batch_connect:
    ssh_allow: false
```
