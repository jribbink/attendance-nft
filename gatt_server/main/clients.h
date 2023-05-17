#ifndef CLIENTS_H
#define CLIENTS_H

#include "common.h"

#define MAX_CLIENTS 9

typedef struct {
  uint16_t connId;
  address flowAddress;
  uint64_t sequenceNum;
  uint8_t referenceBlockId[32];
  uint8_t issetMask;
} client_t;

extern client_t clients[MAX_CLIENTS];

int8_t client_add(uint16_t connId);
int8_t client_remove(uint16_t connId);
client_t* client_find(uint16_t connId);
int8_t sign_client_tx(client_t *client, uint8_t signature[64]);

#endif // CLIENTS_H