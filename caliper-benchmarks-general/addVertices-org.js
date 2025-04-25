'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');
const fs = require('fs');

class AddVerticesWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.vertices = [];
        this.currentIndex = 0;
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        
        // Wczytanie danych z pliku JSON
        try {
            const rawData = fs.readFileSync(roundArguments.graphFile);
            const graphData = JSON.parse(rawData);
            this.vertices = graphData.vertices;
            console.log(`Worker ${workerIndex}: Loaded ${this.vertices.length} vertices from file`);
        } catch (error) {
            console.error(`Worker ${workerIndex}: Failed to load graph file: ${error}`);
            throw error;
        }
    }

    async submitTransaction() {
        if (this.currentIndex >= this.vertices.length) {
            this.currentIndex = 0; // Zaczynamy od początku jeśli skończyły się wierzchołki
        }

        const vertex = this.vertices[this.currentIndex];
        this.currentIndex++;

        const request = {
            contractId: this.roundArguments.contractId,
            contractFunction: 'addVertex',
            invokerIdentity: 'admin',
            contractArguments: [vertex.id],
            readOnly: false
        };

        await this.sutAdapter.sendRequests(request);
    }

    async cleanupWorkloadModule() {
        console.log(`Worker ${this.workerIndex}: Vertices addition test completed`);
    }
}

function createWorkloadModule() {
    return new AddVerticesWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;