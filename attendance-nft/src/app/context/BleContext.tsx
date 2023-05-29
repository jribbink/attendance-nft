const SECONDS_TO_SCAN_FOR = 7;
const SERVICE_UUIDS: string[] = [];
const ALLOW_DUPLICATES = true;

import TypedEmitter from "typed-emitter";
import { NativeEventEmitter, NativeModules } from "react-native";
import BleManager, {
  BleDisconnectPeripheralEvent,
  BleManagerDidUpdateValueForCharacteristicEvent,
  BleScanCallbackType,
  BleScanMatchMode,
  BleScanMode,
  Peripheral,
} from "react-native-ble-manager";
import { Location } from "../models/Location";
import { createContext, useRef } from "react";
import * as fcl from "@onflow/fcl";
import { Event } from "@onflow/typedefs";
import { EventEmitter } from "events";

const BleManagerModule = NativeModules.BleManager;
const bleManagerEmitter = new NativeEventEmitter(BleManagerModule);

const BADGE_CREATION_EVENT =
  "A.1d4e3f4f4c4275626c69632e4d6f6e65792e4d696e696e67436f6e7472616374.Mine";

declare module "react-native-ble-manager" {
  // enrich local contract with custom state properties needed by App.tsx
  interface Peripheral {
    connected?: boolean;
    connecting?: boolean;
  }
}

export const BleContext = createContext<BadgeBleManager | null>(null);

export default function BleContextProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const manager = useRef<BadgeBleManager>(new BadgeBleManager()).current;

  return <BleContext.Provider value={manager}>{children}</BleContext.Provider>;
}

type BadgeBleManagerEvents = {
  locationFound: (location: Location) => void;
};

export class BadgeBleManager extends (EventEmitter as unknown as new () => TypedEmitter<BadgeBleManagerEvents>) {
  constructor() {
    super();
  }

  claimBadge = async (locationId: string) => {
    const txid = await fcl.mutate({
      cadence: `
      DO SOME CADENCE
      `,
      limit: 9999,
    });

    const status = await fcl
      .tx(txid)
      .onceSealed()
      .then(async (status) => {
        if (status.errorMessage) {
          throw new Error(status.errorMessage);
        }
        return status;
      });

    const badgeCreationEvent = status.events.find((event: Event) => {
      return event.type === BADGE_CREATION_EVENT;
    });

    if (!badgeCreationEvent) {
      throw new Error("No badge creation event found");
    }

    const badgeId = badgeCreationEvent.data.id;
    const badge = await fcl.query({
      cadence: `
      DO SOME CADENCE
      `,
      args: (arg, t) => [arg("somearg", fcl.t.String)],
    });

    // Return a list of events
    return badge;
  };
}
