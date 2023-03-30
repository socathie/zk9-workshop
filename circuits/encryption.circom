pragma circom 2.0.0;

include "./utils/encrypt.circom";

template Main() {
    // public inputs
    signal input public_key[2];

    // private inputs
    signal input in[1000]; // zero-padded at the end
    signal input private_key;

    // outputs
    signal output hash;
    signal output shared_key;
    signal output out[1001];

    // TODO: initialize components for hashing and encryption
    // component hasher = ...
    // component enc = ...

    // TODO: feed public and private keys into encryption component
    // enc.public_key[0] <== ...
    // enc.public_key[1] <== ...
    // enc.private_key <== ...

    for (var i = 0; i < 1000; i++) {
        // TODO: feed inputs into hasher and encryption components
        // hasher.in[i] <== ...
        // enc.in[i] <== ...
    }

    // TODO: connect outputs
    // hash <== ...
    // shared_key <== ...

    for (var i = 0; i < 1001; i++) {
        out[i] <== enc.out[i];
    }
}

// TODO: make public key a public input
// component main { public [ ... ] } = Main();