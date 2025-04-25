'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');
const path = require('path');
const fs = require('fs');


class MyWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.vertices = [];
        this.edges = [];
        this.vertexIds = [];
        this.myEdges = []; // krawędzie przypisane danemu workerowi
        this.edgeCounter = 0;
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        
         const request = {
           contractId: this.roundArguments.contractId,
           contractFunction: 'deleteAllFromState',
           invokerIdentity: 'admin',
           contractArguments: [],
           readOnly: false
        };
         await this.sutAdapter.sendRequests(request);
        // Wczytanie pliku JSON na każdym workerze (aby każdy miał dostęp do pełnych danych)
        const graphFile = roundArguments.graphFile || '/data/generated_graphs/graph_1org_test.json';
        const filePath = path.resolve(__dirname, graphFile);
        const jsonData = fs.readFileSync(filePath, 'utf8');
        const graph = JSON.parse(jsonData);
        this.vertices = graph.vertices || [];
        this.edges = graph.edges || [];

       
        this.myEdges = [];
        for (let i = workerIndex; i < this.edges.length; i += totalWorkers) {
            this.myEdges.push(this.edges[i]);
        }
        console.log(`Worker ${workerIndex}: assigned ${this.myEdges.length} edges out of ${this.edges.length}`);

        if (workerIndex === 0) {
            for (const vertex of this.vertices) {
                this.vertexIds.push(vertex.id);
                console.log(`Creating vertex ${vertex.id} with type ${vertex.type}`);
                const request = {
                    contractId: this.roundArguments.contractId,
                    contractFunction: 'addVertex',
                    invokerIdentity: 'admin',
                    contractArguments: [vertex.id],
                    readOnly: false
                };
                await this.sutAdapter.sendRequests(request);
            }
        }
    }

    async submitTransaction() {
        if (this.myEdges.length === 0) {
            console.warn(`Worker ${this.workerIndex}: No edges assigned for transactions.`);
            return;
        }

        const index = this.edgeCounter % this.myEdges.length;
        const edge = this.myEdges[index];
        console.log(`Worker ${this.workerIndex}: Processing edge ${this.edgeCounter + 1}/${this.myEdges.length} from ${edge.src} to ${edge.dst} with perms ${edge.perms}`);
        this.edgeCounter++;

        const request = {
            contractId: this.roundArguments.contractId,
            contractFunction: 'updatePermissions',
            invokerIdentity: 'admin',
            contractArguments: [edge.src, edge.dst, edge.perms, 'ADD'],
            readOnly: false
        };
        await this.sutAdapter.sendRequests(request);
    }
    

    async cleanupWorkloadModule() {
    if (workerIndex === 0) {
      
        console.log(`Worker ${this.workerIndex}: Cleaning up workload.`);
  
     // Przetwarzanie krawędzi
        for (const edge of this.edges) {
            const operation = "ADD";
            console.log(`Worker ${workerIndex}: Creating edge from ${edge.src} to ${edge.dst} with perms ${edge.perms}`);
            const request = {
                contractId: this.roundArguments.contractId,
                contractFunction: 'updatePermissions',
                invokerIdentity: 'admin',
                contractArguments: [edge.src, edge.dst, edge.perms, operation],
                readOnly: false
            };
            await this.sutAdapter.sendRequests(request);
        }
       }
    }
}

function createWorkloadModule() {
    return new MyWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
