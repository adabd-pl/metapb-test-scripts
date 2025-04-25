'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class MyWorkload extends WorkloadModuleBase {
    constructor() {
        super();
    }

	async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        
        const vertices = roundArguments.vertexCount;
        const edgeCount = roundArguments.edges;
        
        console.log(`Worker ${workerIndex}: Initializing workload with ${vertices} vertices and ${edgeCount} edges.`);
        
        let vertexIds = [];
        // Tworzenie wierzchołków
        for (let i = 0; i < vertices; i++) { 
            const vertexId = `V${workerIndex}_${i}`;
            vertexIds.push(vertexId);
            console.log(`Worker ${workerIndex}: Creating vertex ${vertexId}`);
            const request = {
                contractId: roundArguments.contractId,
                contractFunction: 'addVertex',
                invokerIdentity: 'org1-admin-fabric',
                contractArguments: [vertexId],
                readOnly: false
            };
            await this.sutAdapter.sendRequests(request);
        }

        // Generowanie losowych krawędzi
        for (let i = 0; i < edgeCount; i++) {
            const vertex1 = vertexIds[Math.floor(Math.random() * vertexIds.length)];
            const vertex2 = vertexIds[Math.floor(Math.random() * vertexIds.length)];
            const permission = (Math.random() < 0.5) ? '101' : '010';
            const operation = 'ADD';
            
            console.log(`Worker ${workerIndex}: Creating edge from ${vertex1} to ${vertex2} with permission ${permission}`);
            
            const request = {
                contractId: roundArguments.contractId,
                contractFunction: 'updatePermissions',
                invokerIdentity: 'org1-admin-fabric',
                contractArguments: [vertex1, vertex2, permission, operation],
                readOnly: false
            };
            await this.sutAdapter.sendRequests(request);
        }
    }


	async submitTransaction() {
		console.log(`Worker ${this.workerIndex}: Retrieving effective permissions.`);
	
		if (!this.generatedEdges || this.generatedEdges.length < 2) {
			console.error(`Worker ${this.workerIndex}: Not enough edges available for selection.`);
			return;
		}
	
		// Losowanie dwóch różnych krawędzi
		let edge1, edge2;
		do {
			edge1 = this.generatedEdges[Math.floor(Math.random() * this.generatedEdges.length)];
			edge2 = this.generatedEdges[Math.floor(Math.random() * this.generatedEdges.length)];
		} while (edge1 === edge2); // Zapewniamy, że wybrane krawędzie są różne
	
		const source = edge1[0]; // Pobieramy source z pierwszej krawędzi
		const destination = edge2[1]; // Pobieramy destination z drugiej krawędzi
	
		console.log(`Worker ${this.workerIndex}: Checking permissions from ${source} to ${destination}`);
	
		const request = {
			contractId: this.roundArguments.contractId,
			contractFunction: 'getEffectivePermissions',
			invokerIdentity: 'org1-admin-fabric',
			contractArguments: [source, destination],
			readOnly: true
		};
	
		return this.sutAdapter.sendRequests(request);
	}
	

    async cleanupWorkloadModule() {
        console.log(`Worker ${this.workerIndex}: Cleaning up workload.`);
        const request = {
            contractId: this.roundArguments.contractId,
            contractFunction: 'deleteAllFromState',
            invokerIdentity: 'org1-admin-fabric',
            contractArguments: [],
            readOnly: false
        };
        await this.sutAdapter.sendRequests(request);
    }
}

function createWorkloadModule() {
    return new MyWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
