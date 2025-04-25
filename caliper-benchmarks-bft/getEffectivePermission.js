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
    }
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        
        // // Wczytanie pliku JSON (domyślnie "graph.json" lub ścieżka podana w roundArguments.graphFile)
        const graphFile = roundArguments.graphFile || '/data/generated_graphs/graph_1org_test.json';
        const filePath = path.resolve(__dirname, graphFile);
        const jsonData = fs.readFileSync(filePath, 'utf8');
        const graph = JSON.parse(jsonData);
        this.vertices = graph.vertices || [];
        this.edges = graph.edges || [];
        
        // // Przetwarzanie wierzchołków
        for (const vertex of this.vertices) {
            this.vertexIds.push(vertex.id);
            console.log(`Worker ${workerIndex}: Creating vertex ${vertex.id} with type ${vertex.type}`);

        }

        // // Przetwarzanie krawędzi
        // for (const edge of this.edges) {
        //     const operation = "ADD";
        //     console.log(`Worker ${workerIndex}: Creating edge from ${edge.src} to ${edge.dst} with perms ${edge.perms}`);
        //     const request = {
        //     contractId: this.roundArguments.contractId,
        //     contractFunction: 'updatePermissions',
        //     invokerIdentity: 'admin',
        //     contractArguments: [edge.src, edge.dst, edge.perms, operation],
        //     readOnly: false
        //   };
        //   await this.sutAdapter.sendRequests(request);
        //}
    }


    async submitTransaction() {
        console.log(`Worker ${this.workerIndex}: Retrieving effective permissions.`);
    
        // Upewniamy się, że mamy przynajmniej dwa wierzchołki
        if (!this.vertexIds || this.vertexIds.length < 2) {
            console.error(`Worker ${this.workerIndex}: Not enough vertices available for selection.`);
            return;
        }
    
        let source, destination;
        do {
            source = this.vertexIds[Math.floor(Math.random() * this.vertexIds.length)];
            destination = this.vertexIds[Math.floor(Math.random() * this.vertexIds.length)];
        } while (source === destination); // Zapewniamy, że źródło i cel są różne
    
        console.log(`Worker ${this.workerIndex}: Checking permissions from ${source} to ${destination}`);
    
        const request = {
            contractId: this.roundArguments.contractId,
            contractFunction: 'getEffectivePermission',
            invokerIdentity: 'admin',
            contractArguments: [source, destination],
            readOnly: true
        };
    
        return this.sutAdapter.sendRequests(request);
    }
    

    async cleanupWorkloadModule() {
        console.log(`Worker ${this.workerIndex}: Cleaning up workload.`);
        /***
         * const request = {
            contractId: this.roundArguments.contractId,
            contractFunction: 'deleteAllFromState',
            invokerIdentity: 'admin',
            contractArguments: [],
            readOnly: false
        };
        await this.sutAdapter.sendRequests(request);
        ***/
    }
}

function createWorkloadModule() {
    return new MyWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
