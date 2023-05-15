#include "common.h"

char* transaction = "TRANSACTION_CODE_HERE";

size_t uint64_to_bytes(uint64_t val, char* buf) {
  if(val < 0) {
    printf("uint64_to_bytes: val is negative\r\n");
    return 0;
  }
  
  uint8_t len = 0;
  for (int i = sizeof(uint64_t) - 1; i >= 0; i--) {
    uint8_t curr = (val >> (i * 8)) & 0xFF;
    if(curr > 0 && len == 0) {
        len = i + 1;
    }
    if(len > 0) {
        buf[i] = (val >> (i * 8)) & 0xFF;
    }
  }
  return MAX(len, 1);
}

void create_tx_payload(uint8_t *rlpTx, size_t rlpTxSize, address userAddress, uint8_t sequenceNum, uint8_t referenceBlockId[32]) {
  // Encode script
  RlpElement_t script = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = transaction,
    .len = strlen(transaction)
  };

  // Encode arguments
  RlpElement_t arguments = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = 0,
    .len = 0
  };

  // Encode refBlock
  RlpElement_t refBlock = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = 0,
    .len = 0
  };

  // Encode computeLimit
  char _computeLimit[8];
  int computeLimitLen = uint64_to_bytes(1000, _computeLimit);
  RlpElement_t computeLimit = {
    .type = RLP_TYPE_INT64,
    .buff = _computeLimit,
    .len = computeLimitLen
  };

  // Encode proposalKey address
  RlpElement_t proposalKeyAddress = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = NODE_FLOW_ADDRESS,
    .len = 8
  };

  // Encode proposalKey keyId
  char _proposalKeyId[8];
  int proposalKeyIdLen = uint64_to_bytes(0, _proposalKeyId);
  RlpElement_t proposalKeyId = {
    .type = RLP_TYPE_INT64,
    .buff = _proposalKeyId,
    .len = proposalKeyIdLen
  };

  // Encode proposalKey sequenceNum
  char _sequenceNumBytes[8];
  int sequenceNumBytesLen = uint64_to_bytes(sequenceNum, _sequenceNumBytes);
  RlpElement_t proposalKeySequenceNum = {
    .type = RLP_TYPE_INT64,
    .buff = _sequenceNumBytes,
    .len = sequenceNumBytesLen
  };

  // Encode payer
  RlpElement_t payer = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = userAddress,
    .len = 8
  };

  // Encode authorizers
  RlpElement_t nodeAuthorizer = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = NODE_FLOW_ADDRESS,
    .len = 8
  };

  RlpElement_t userAuthorizer = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = userAddress,
    .len = 8
  };

  RlpElement_t const *const authorizersList[] = {&nodeAuthorizer, &userAuthorizer};
  uint8_t authorizersRlp[1024];

  int outputLen = 0;
  outputLen = rlp_encode_list(authorizersRlp, sizeof(authorizersRlp), authorizersList, sizeof(authorizersList)/sizeof(authorizersList[0]));

  if (outputLen < 0) {
    ESP_LOGE(GATTS_TAG, "rlp encoding authorizers error, return code: %d\r\n", outputLen);
    return;
  }

  RlpElement_t authorizers = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = &authorizersRlp,
    .len = outputLen
  };

  // Encode tx
  RlpElement_t const *const flowTxn[] = {
    &script,
    &arguments,
    &refBlock,
    &computeLimit,
    &proposalKeyAddress,
    &proposalKeyId,
    &proposalKeySequenceNum,
    &payer,
    &authorizers
  };

  outputLen = rlp_encode_list(rlpTx, rlpTxSize, flowTxn, sizeof(flowTxn)/sizeof(flowTxn[0]));
  if (outputLen < 0) {
    ESP_LOGE(GATTS_TAG, "rlp encoding flow txn error, return code: %d\r\n", outputLen);
    return;
  }
}