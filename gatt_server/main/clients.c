#include "clients.h"
#include "encode.h"
#include <tinycrypt/sha256.h>
#include <tinycrypt/ecc_dsa.h>
#include <tinycrypt/ecc.h>
#include <tinycrypt/constants.h>

client_t clients[MAX_CLIENTS];

int8_t client_add(uint16_t connId) {
  int8_t i = 0;
  for (; i < MAX_CLIENTS; i++) {
    if(!(clients[i].issetMask & 1)) break;
  }
  if(i == MAX_CLIENTS) return -1;

  clients[i].connId = connId;
  clients[i].issetMask = 1;
  return i;
}

int8_t client_remove(uint16_t connId) {
  for(uint8_t i = 0; i < MAX_CLIENTS; i++) {
    if(clients[i].connId == connId) {
      clients[i].issetMask = 0;
      return i;
    }
  }
  return -1;
}

client_t* client_find(uint16_t connId) {
  for(uint8_t i = 0; i < MAX_CLIENTS; i++) {
    if(clients[i].connId == connId) {
      return &clients[i];
    }
  }
  return NULL;
}

// Function to hash and sign the transaction
int8_t sign_client_tx(client_t *client, uint8_t signature[64]) {
  uint8_t* payload = malloc(2048);
  uint8_t payloadLen = encode_tx_payload(payload, 2048, client->flowAddress, client->sequenceNum, client->referenceBlockId);
  payload = realloc(payload, payloadLen);

  uint8_t hash[32];
  struct tc_sha256_state_struct hashState;
  tc_sha256_init(&hashState);
  tc_sha256_update(&hashState, payload, payloadLen);
  tc_sha256_final(hash, &hashState);

  free(payload);

  //print hash for debugging using esp-idf hex buffer
  ESP_LOGI(GATTS_TAG, "Hash: ");
  esp_log_buffer_hex(GATTS_TAG, hash, 32);
  
  // Sign the hash using NODE_PRIVATE_KEY
  int ret = uECC_sign(NODE_PRIVATE_KEY, hash,
	      32, signature, uECC_secp256r1());
  if(ret != TC_CRYPTO_SUCCESS) {
    printf("Error signing transaction\n");
    return -1;
  }

  return 0;
}