# metapb-test-scripts

Test and benchmark scripts for a **Meta Policy-Based (MetaPB)** access control system deployed on **Hyperledger Fabric 3.x** running on **Kubernetes** (via HLF Operator). Includes automated network setup scripts, Caliper benchmark configurations, and graph generation tools.

---

## Description

This repository contains everything needed to:
- Deploy and configure a Hyperledger Fabric network (BFT and Raft consensus) on Kubernetes
- Run performance benchmarks using **Hyperledger Caliper**
- Generate test permission graphs for the MetaPB smart contract
- Automate network operations (add peers, orderers, channels, deploy chaincode)

---

## Quick Start

### 1. Prepare environment

```bash
source automated-scripts/prepare-env.sh
```

### 2. Create a BFT channel

```bash
bash automated-scripts/channel-bft.sh
```

### 3. Deploy chaincode

```bash
bash automated-scripts/chaincode-deploy2-ok.sh
```

### 4. Run Caliper benchmarks

```bash
kubectl apply -f deploy-caliper-bft.yaml
```
