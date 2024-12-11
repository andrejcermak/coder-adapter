# coder-adapter
Coder adapter to add OpenStack support in Open OnDemand. Part of my Master thesis

## Prerequisites
1. Running instance of Open OnDemand
2. Running coder environment
3. Have generated Coder API token in [https://coder.com/docs/admin/users/sessions-tokens]

## How to use
1. `cd /opt/ood/gems/gems/ood_core-0.25.0/lib/ood_core/job/adapters/`
2. `git clone git@github.com:andrejcermak/coder-adapter.git`
3. Define cluster under `/etc/ood/config/clusters.d` using following .yaml file
4. Enable pun_pre_hook scripts in the `ood_portal.yml` configuration file
5. Deploy authentication hook to `/etc/ood/config` and source it in `pun_pre_hook.sh`
6. Deploy Coder template  (for example [OpenStack VM](https://github.com/andrejcermak/coder_template_os_vm) or [on-premise Kubernetes](https://github.com/andrejcermak/coder_template_kubernetes))
7. Deploy Open OnDemand interactive application in `/var/www/ood/apps/sys` (for example [OpenStack VM](https://github.com/andrejcermak/bc_openstack_vm) or [on-premise Kubernetes](https://github.com/andrejcermak/bc_openstack_k8s))

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
```
