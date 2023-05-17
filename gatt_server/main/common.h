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
static address NODE_FLOW_ADDRESS = {0xcb, 0xa5, 0x48, 0x46, 0x25, 0x47, 0xef, 0x17};

// Private key of the node
static uint8_t NODE_PRIVATE_KEY[32] = {0x4b,0xef,0x65,0xff,0x18,0x33,0x46,0xba,0x62,0x3e,0x4f,0x8f,0x3b,0x95,0xd0,0xad,0x14,0x64,0x27,0x50,0xd6,0xe2,0xa3,0x90,0x14,0x5a,0x2e,0x8d,0x46,0x4b,0xcd,0x70};


#endif // COMMON_H