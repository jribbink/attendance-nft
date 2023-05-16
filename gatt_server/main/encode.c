#include "common.h"

char* transaction = "TRANSACTION_CODE_HERE";

uint8_t uint64_to_bytes(uint64_t val, uint8_t* buf) {
  uint8_t len = 0;
  for (int i = sizeof(uint64_t) - 1; i >= 0; i--) {
    uint8_t curr = (val >> (i * 8)) & 0xFF;
    if(curr > 0 && len == 0) {
        len = i + 1;
    }
    if(len > 0) {
        buf[len-i-1] = curr;
    }
  }
  return len;
}

int encode_tx_payload(uint8_t *rlpTx, size_t rlpTxSize, address userAddress, uint8_t sequenceNum, uint8_t referenceBlockId[32]) {
  int outputLen = 0;
  
  // Encode script
  RlpElement_t script = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = transaction,
    .len = strlen(transaction)
  };

  RlpElement_t const *const argumentsList[] = {};
  uint8_t* argumentsRlp = malloc(100);
  outputLen = rlp_encode_list(argumentsRlp, 100, argumentsList, 0);

  if (outputLen < 0) {
    ESP_LOGE(GATTS_TAG, "rlp encoding arguments error, return code: %d\r\n", outputLen);
    return 0;
  }

  // Resize authorizersRlp
  argumentsRlp = realloc(argumentsRlp, outputLen);

  // Encode arguments
  RlpElement_t arguments = {
    .type = RLP_TYPE_ENCODED_DATA,
    .buff = argumentsRlp,
    .len = outputLen
  };

  // Encode refBlock
  RlpElement_t refBlock = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = referenceBlockId,
    .len = 32
  };

  // Encode computeLimit
  uint8_t _computeLimit[8];
  uint8_t computeLimitLen = uint64_to_bytes(1000, _computeLimit);
  RlpElement_t computeLimit = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = _computeLimit,
    .len = computeLimitLen
  };

  // Encode proposalKey address
  RlpElement_t proposalKeyAddress = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = userAddress,
    .len = 8
  };

  // Encode proposalKey keyId
  uint8_t _proposalKeyId[8];
  uint8_t proposalKeyIdLen = uint64_to_bytes(0, _proposalKeyId);
  RlpElement_t proposalKeyId = {
    .type = RLP_TYPE_BYTE_ARRAY,
    .buff = _proposalKeyId,
    .len = proposalKeyIdLen
  };

  // Encode proposalKey sequenceNum
  uint8_t _sequenceNumBytes[8];
  uint8_t sequenceNumBytesLen = uint64_to_bytes(sequenceNum, _sequenceNumBytes);
  RlpElement_t proposalKeySequenceNum = {
    .type = RLP_TYPE_BYTE_ARRAY,
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

  // Encode authorizers list
  RlpElement_t const *const authorizersList[] = {&nodeAuthorizer, &userAuthorizer};
  uint8_t* authorizersRlp = malloc(1000);
  outputLen = rlp_encode_list(authorizersRlp, 1000, authorizersList, sizeof(authorizersList)/sizeof(authorizersList[0]));

  if (outputLen < 0) {
    ESP_LOGE(GATTS_TAG, "rlp encoding authorizers error, return code: %d\r\n", outputLen);
    return 0;
  }

  // Resize authorizersRlp
  authorizersRlp = realloc(authorizersRlp, outputLen);

  RlpElement_t authorizers = {
    .type = RLP_TYPE_ENCODED_DATA,
    .buff = authorizersRlp,
    .len = outputLen
  };

  // Encode tx list
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
  
  // Free memory
  free(authorizersRlp);
  free(argumentsRlp);

  // Check for errors
  if (outputLen < 0) {
    ESP_LOGE(GATTS_TAG, "rlp encoding flow txn error, return code: %d\r\n", outputLen);
    return 0;
  }

  return outputLen;
}