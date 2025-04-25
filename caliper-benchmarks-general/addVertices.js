'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class MyWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.vertexCounter = 0;
        this.vertexTypes = ['user', 'group', 'space'];
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        console.log(`Worker ${workerIndex} initialized.`);
    }

    getRandomType() {
        const index = Math.floor(Math.random() * this.vertexTypes.length);
        return this.vertexTypes[index];
    }

    async submitTransaction() {
        const randomSuffix = Math.floor(Math.random() * 1e9); // losowa liczba 0–999,999,999
        const vertexId = `v_${this.workerIndex}_${this.vertexCounter}_${randomSuffix}`;
        const vertexType = this.getRandomType();
        this.vertexCounter++;

        const request = {
            contractId: this.roundArguments.contractId,
            contractFunction: 'addVertex',
            invokerIdentity: 'admin',
            contractArguments: [vertexId],
            readOnly: false
        };

        console.log(`Worker ${this.workerIndex}: Adding vertex ${vertexId} with type ${vertexType}`);
        await this.sutAdapter.sendRequests(request);
    }

    async cleanupWorkloadModule() {
        console.log(`Worker ${this.workerIndex}: cleanup complete.`);
    }
}

function createWorkloadModule() {
    return new MyWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
