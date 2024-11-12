# Kubernetes Cluster Deployer and Withdrawer

Based on the previous works of szefoka/openfaas_lab and danielkeszei/thesis_scripts.

---

## Available CNI plugins (as for now)

- Flannel
- WeaveNet

---

## User's Manual

### Preparations

The commands must be run as root on the (future) master node. The SSH-key of the master node must be uploaded
on the worker node for root, so it can run seamlessly.

Create a `worker.list` file and add the hostname or the IP address of the worker nodes in it line-by-line
as you can see in the example file.

### Deploying Kubernetes Cluster

To install the cluster run the `./cluster-deploy [--external|-e] <CNI>` command. A Kubernetes CNI plugin name
must be given as an argument. If you give the word `help` as an argument, you will get the script usage
with the available CNI plugins.

### Withdraw Kubernetes Cluster

To undo the cluster installation run the `./cluster-withdraw` command and it will clean up the configurations
on all nodes including the master as well. Command will purge all Kubernetes setups from nodes enlisted
in the `worker.list` file!

---

## Használati útmutató

### Előkészületek

A parancsokat root-tal kell futtatni a (leendő) mester gépen. A worker gépek root felhasználójához töltsétek fel
a mester SSH-kulcsát, így jelszókérés nem állítja meg a telepítési folyamatokat.

Hozz létre egy `worker.list` fájlt, mely soronként tartalmazza a worker gépek hosztnevét vagy IP címét, ahogy
a példa fájlban is látható.

### Kubernetes Klaszter létrehozása

A klaszter létrehozásához futtasd le a `./cluster-deploy <cni>` parancsot. Paraméterként meg kell adni a Kubernetes
klaszter hálózati bővítményét. Ha a `help` paraméterrel futtatod, akkor megkapod használati útmutatót és az elérhető
Kubernetes CNI bővítmények listáját.

#### Klaszter létrehozás példa:

```sh
vim worker.list # Hozzáadjuk a workereket
# Elhelyezük a workerek ssh kulcsát a .ssh mappába (id_rsa néven)
./cluster_deploy weavenet # Létrehozzuk a clustert weavenet-el
# várunk egy kicsit amíg elindulnak a nodeok
kubectl get nodes -owide # ellenőrizzük, hogy a kalszter minden tagja online-e
```

### Kubernetes Klaszter eltávolítása

A klaszter visszavonásához a `./cluster-withdraw` parancsot kell lefuttatni, és ezután eltávolítja az összes klaszter
beállítást a gépeken, beleértve a mester gépet is. A parancs letörli az összes Kubernetes beállítást a hosztokról,
melyek a `worker.list` fájlban szerepelnek!
