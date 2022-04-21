# Elixir Clusters on Kubernetes

This idea is based on using pure Erlang/OTP paradigms where we keep long-running processes and use
distributed supervisors and registries to keep the various states up to date.

 - Cluster: [LibCluster](https://github.com/bitwalker/libcluster)
 - Manage processes across nodes: [Horde Supervisor](https://github.com/derekkraan/horde)
 - Transfer (hand off) state: CRDT
 - Registry: Horde Registry

There are a couple of issues with this approach:

 1. When a process crashes for unexpected reasons, the state is lost. There might be a way to
    monitor these processes and attempt to hand off the state to a new process when that happens,
    but I haven't come across any off-the-shelf library which can do this.

 2. The state needs to change according to external events. We could implement this via a push
    mechanism (i.e.: an external API, which comes with its own security issues) or via a pull one
    (Redis or Postgres, etc..., introducing a dependency to an external resource).

## Usage

Manage the cluster:

```
gcloud container clusters create hello-cluster --num-nodes=2 --region=europe-west1
gcloud container clusters get-credentials hello-cluster --region=europe-west1

gcloud builds submit --tag=gcr.io/${PROJECT}/hello:v1.11 .

kubectl apply -f kubernetes-config/deployment.yaml
kubectl apply -f kubernetes-config/service.yaml

gcloud container clusters delete hello-cluster --region=europe-west1
```

Add/read records in Mnesia:

```elixir
Hello.EventStore.create(%Hello.EventStore.Event{ id: 1, name: "Ricky", caretaker_id: nil })
Hello.EventStore.list()
```
