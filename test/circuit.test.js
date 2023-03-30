const chai = require("chai");

const fs = require("fs");
const crypto = require("crypto");
const base32 = require("base32.js");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;

const { Keypair } = require("circomlib-ml/test/modules/maci-domainobjs");
const { decrypt } = require("circomlib-ml/test/modules/maci-crypto");

const labels = require("../assets/labels.json");
const json = require("../circuits/model.json");

// read ../assets/cid.txt into an array of strings
const cids = fs.readFileSync("./assets/cid.txt").toString().split("\n");

const idx = 3;

let modelHash;

describe("circuit.circom test", function () {
    this.timeout(100000000);

    let INPUT = {};

    for (const [key, value] of Object.entries(json)) {
        if (Array.isArray(value)) {
            let tmpArray = [];
            for (let i = 0; i < value.flat().length; i++) {
                tmpArray.push(Fr.e(value.flat()[i]));
            }
            INPUT[key] = tmpArray;
        } else {
            INPUT[key] = Fr.e(value);
        }
    }

    const bytes = fs.readFileSync("assets/" + idx + ".pgm");
    const binary = [...bytes].map((b) => b.toString(2).padStart(8, "0").split("")).flat();

    INPUT["in"] = binary;

    let witness;

    before(async () => {
        const circuit = await wasm_tester("./circuits/prediction.circom");
        witness = await circuit.calculateWitness(INPUT);
        modelHash = witness[4];
        // console.log(witness.slice(1, 5));
    });


    it("Should make prediction", async () => {
        assert.equal(witness[1], labels[idx]);
    });

    it("Should match cid", async () => {
        const cid_version = 1;
        const cid_codec = 85; // raw 0x55
        const hash_function_code = 18; // SHA-256 0x12
        const length = 32;

        const hash = witness[2].toString(16).padStart(32, "0") + witness[3].toString(16).padStart(32, "0");
        const cidraw = cid_version.toString(16).padStart(2, "0") + cid_codec.toString(16).padStart(2, "0") + hash_function_code.toString(16).padStart(2, "0") + length.toString(16).padStart(2, "0") + hash;

        const buf = Buffer.from(cidraw, 'hex');
        const encoder = new base32.Encoder();
        const cid = encoder.write(buf).finalize().toLowerCase();
        assert.equal("b" + cid, cids[idx]);
    });
});

describe("encryption.circom test", function () {
    this.timeout(100000000);

    let input = [];

    for (const [key, value] of Object.entries(json)) {
        // console.log(key);
        if (Array.isArray(value)) {
            let tmpArray = [];
            for (let i = 0; i < value.flat().length; i++) {
                tmpArray.push(Fr.e(value.flat()[i]));
            }
            input = [...input, ...tmpArray];
        } else {
            input.push(value);
        }
    }

    for (let i = input.length; i < 1000; i++) {
        input.push(0);
    }

    let INPUT = {};

    let keypair;
    let keypair2;

    let ecdhSharedKey;

    let witness;

    before(async function () {
        keypair = new Keypair();
        keypair2 = new Keypair();

        ecdhSharedKey = Keypair.genEcdhSharedKey(
            keypair.privKey,
            keypair2.pubKey,
        );

        INPUT = {
            'private_key': keypair.privKey.asCircuitInputs(),
            'public_key': keypair2.pubKey.asCircuitInputs(),
            'in': input,
        }

        const circuit = await wasm_tester("./circuits/encryption.circom");
        witness = await circuit.calculateWitness(INPUT);
        // console.log(witness[1], witness[2], witness[1004], witness[1005]);
    });

    it("Check circuit output", async () => {
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(modelHash)));
        assert(Fr.eq(Fr.e(witness[2]),Fr.e(ecdhSharedKey)));
        assert(Fr.eq(Fr.e(witness[1004]),Fr.e(INPUT['public_key'][0])));
        assert(Fr.eq(Fr.e(witness[1005]),Fr.e(INPUT['public_key'][1])));
    });

    it("Decryption should match", async function () {
        const ciphertext = {
            iv: witness[3],
            data: witness.slice(4,1005),
        }

        const decrypted = decrypt(ciphertext, ecdhSharedKey);

        for (let i = 0; i < 1000; i++) {
            assert(Fr.eq(Fr.e(decrypted[i]), Fr.e(input[i])));
        }
    });
});