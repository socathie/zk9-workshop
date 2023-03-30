pragma circom 2.0.0;

include "./model.circom";
include "./utils/cid.circom";
include "./utils/encrypt.circom";

template Main() {
    // private inputs
    signal input in[797*8];
    signal input conv2d_weights[3][3][1][4];
    signal input conv2d_bias[4];
    signal input batch_normalization_a[4];
    signal input batch_normalization_b[4];
    signal input conv2d_1_weights[3][3][4][16];
    signal input conv2d_1_bias[16];
    signal input batch_normalization_1_a[16];
    signal input batch_normalization_1_b[16];
    signal input dense_weights[16][10];
    signal input dense_bias[10];

    // outputs
    signal output out;
    signal output cids[2];
    signal output hash;

    // recurring components
    component pixel;
    component model;
    component cid;

    model = Model();
    pixel = getPixels();
    cid = getCid();

    for (var i = 0; i < 797*8; i++) {
        pixel.in[i] <== in[i];
        cid.in[i] <== in[i];
    }

    // get cid
    for (var i = 0; i < 2; i++) {
        cids[i] <== cid.out[i];
    }

    for (var i0 = 0; i0 < 28; i0++) {
        for (var i1 = 0; i1 < 28; i1++) {
            for (var i2 = 0; i2 < 1; i2++) {
                model.in[i0][i1][i2] <== pixel.out[i0][i1][i2];
    }}}

    for (var i0 = 0; i0 < 3; i0++) {
        for (var i1 = 0; i1 < 3; i1++) {
            for (var i2 = 0; i2 < 1; i2++) {
                for (var i3 = 0; i3 < 4; i3++) {
                    model.conv2d_weights[i0][i1][i2][i3] <== conv2d_weights[i0][i1][i2][i3];
    }}}}
    for (var i0 = 0; i0 < 4; i0++) {
        model.conv2d_bias[i0] <== conv2d_bias[i0];
    }

    for (var i0 = 0; i0 < 4; i0++) {
        model.batch_normalization_a[i0] <== batch_normalization_a[i0];
    }
    for (var i0 = 0; i0 < 4; i0++) {
        model.batch_normalization_b[i0] <== batch_normalization_b[i0];
    }

    for (var i0 = 0; i0 < 3; i0++) {
        for (var i1 = 0; i1 < 3; i1++) {
            for (var i2 = 0; i2 < 4; i2++) {
                for (var i3 = 0; i3 < 16; i3++) {
                    model.conv2d_1_weights[i0][i1][i2][i3] <== conv2d_1_weights[i0][i1][i2][i3];
    }}}}
    for (var i0 = 0; i0 < 16; i0++) {
        model.conv2d_1_bias[i0] <== conv2d_1_bias[i0];
    }

    for (var i0 = 0; i0 < 16; i0++) {
        model.batch_normalization_1_a[i0] <== batch_normalization_1_a[i0];
    }
    for (var i0 = 0; i0 < 16; i0++) {
        model.batch_normalization_1_b[i0] <== batch_normalization_1_b[i0];
    }

    for (var i0 = 0; i0 < 16; i0++) {
        for (var i1 = 0; i1 < 10; i1++) {
            model.dense_weights[i0][i1] <== dense_weights[i0][i1];
    }}
    for (var i0 = 0; i0 < 10; i0++) {
        model.dense_bias[i0] <== dense_bias[i0];
    }

    out <== model.out[0];

    // hash model weights

    component mimc = hash1000();
    var idx = 0;

    for (var i0 = 0; i0 < 3; i0++) {
        for (var i1 = 0; i1 < 3; i1++) {
            for (var i2 = 0; i2 < 1; i2++) {
                for (var i3 = 0; i3 < 4; i3++) {
                    mimc.in[idx] <== conv2d_weights[i0][i1][i2][i3];
                    idx++;
    }}}}

    for (var i0 = 0; i0 < 4; i0++) {
        mimc.in[idx] <== conv2d_bias[i0];
        idx++;
    }

    for (var i0 = 0; i0 < 4; i0++) {
            mimc.in[idx] <== batch_normalization_a[i0];
            idx++;
    }
    for (var i0 = 0; i0 < 4; i0++) {
        mimc.in[idx] <== batch_normalization_b[i0];
        idx++;
    }

    for (var i0 = 0; i0 < 3; i0++) {
        for (var i1 = 0; i1 < 3; i1++) {
            for (var i2 = 0; i2 < 4; i2++) {
                for (var i3 = 0; i3 < 16; i3++) {
                    mimc.in[idx] <== conv2d_1_weights[i0][i1][i2][i3];
                    idx++;
    }}}}
    for (var i0 = 0; i0 < 16; i0++) {
        mimc.in[idx] <== conv2d_1_bias[i0];
        idx++;
    }

    for (var i0 = 0; i0 < 16; i0++) {
        mimc.in[idx] <== batch_normalization_1_a[i0];
        idx++;
    }
    for (var i0 = 0; i0 < 16; i0++) {
        mimc.in[idx] <== batch_normalization_1_b[i0];
        idx++;
    }

    for (var i0 = 0; i0 < 16; i0++) {
        for (var i1 = 0; i1 < 10; i1++) {
            mimc.in[idx] <== dense_weights[i0][i1];
            idx++;
    }}
    for (var i0 = 0; i0 < 10; i0++) {
        mimc.in[idx] <== dense_bias[i0];
        idx++;
    }

    // padding
    for (var i = idx; i < 1000; i++) {
        mimc.in[i] <== 0;
    }

    hash <== mimc.out;
}

component main = Main();