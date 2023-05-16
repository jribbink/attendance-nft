#ifndef ENCODE_H
#define ENCODE_H

#include "common.h"

int encode_tx_payload(uint8_t *rlpTx, size_t rlpTxSize, address userAddress, uint8_t sequenceNum, uint8_t referenceBlockId[32]);


#endif // ENCODE_H