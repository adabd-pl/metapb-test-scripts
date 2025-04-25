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

        if (workerIndex === 0 && graph.vertices.length > 0) {
            // Obliczone parametry na podstawie danych: 3322 vertices = 1,257,143 bytes
            const BYTES_PER_VERTEX = 378; // 1,257,143 / 3322 ≈ 378 bytes per vertex
            const MAX_PAYLOAD_SIZE = 950000; // 950KB (bezpieczny margines poniżej 1MB)
            const IDEAL_BATCH_SIZE = Math.floor(MAX_PAYLOAD_SIZE / BYTES_PER_VERTEX); // ≈2510/378≈251 vertices
            
            // Bezpieczny batch (60% maksymalnej pojemności)
            const SAFE_BATCH_SIZE = Math.floor(IDEAL_BATCH_SIZE * 0.6); // ≈150 vertices
            
            console.log(`Processing ${graph.vertices.length} vertices with batch size ${SAFE_BATCH_SIZE}`);
        
            for (let i = 0; i < graph.vertices.length; i += SAFE_BATCH_SIZE) {
                const batch = graph.vertices.slice(i, i + SAFE_BATCH_SIZE);
                const verticesPayload = {
                    vertices: batch.map(v => ({
                        id: v.id,
                        type: v.type
                    }))
                };
        
                const payloadSize = JSON.stringify(verticesPayload).length;
                if (payloadSize > MAX_PAYLOAD_SIZE) {
                    throw new Error(`Calculated batch size too large: ${payloadSize} bytes`);
                }
        
                const batchRequest = {
                    contractId: this.roundArguments.contractId,
                    contractFunction: 'addVerticesFromJSON',
                    invokerIdentity: 'admin',
                    contractArguments: [JSON.stringify(verticesPayload)],
                    readOnly: false
                };
        
                console.log(`Adding batch [${i}-${i + batch.length}] (${payloadSize} bytes)`);
                await this.sutAdapter.sendRequests(batchRequest);
                
                // Małe opóźnienie między batchami dla stabilności
                if (i + SAFE_BATCH_SIZE < graph.vertices.length) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                }
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
   // if (this.workerIndex === 0) {
      
     //   console.log(`Worker ${this.workerIndex}: Cleaning up workload.`);
  
     // Przetwarzanie krawędzi
        // for (const edge of this.edges) {
        //     const operation = "ADD";
        //     console.log(`Worker ${workerIndex}: Creating edge from ${edge.src} to ${edge.dst} with perms ${edge.perms}`);
        //     const request = {
        //         contractId: this.roundArguments.contractId,
        //         contractFunction: 'updatePermissions',
        //         invokerIdentity: 'admin',
        //         contractArguments: [edge.src, edge.dst, edge.perms, operation],
        //         readOnly: false
        //     };
        //     await this.sutAdapter.sendRequests(request);
        // }
     //  }
    }
}

function createWorkloadModule() {
    return new MyWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
