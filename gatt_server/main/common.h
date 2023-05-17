#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_bt.h"

#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_bt_defs.h"
#include "esp_bt_main.h"
#include "esp_gatt_common_api.h"

#include "sdkconfig.h"

#include <rlp.h>
#include <tinycrypt/sha256.h>


#define GATTS_TAG "GATTS_DEMO"

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b)) 

typedef uint8_t address[8];

// Node address on the blockchain
static address NODE_FLOW_ADDRESS = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01};

// Private key of the node
static uint8_t NODE_PRIVATE_KEY[32] = {0x2d,0xbd,0xb5,0x28,0x20,0xbf,0xad,0x2a,0x41,0x64,0xc6,0xe8,0x0a,0x7c,0x79,0xb9,0xf4,0xc5,0x43,0x83,0x51,0x7c,0x7a,0x64,0xe5,0xe8,0x8e,0xc0,0xb8,0xe9,0x92,0x53};


#endif // COMMON_H