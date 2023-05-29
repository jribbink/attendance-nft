import { useContext } from "react";
import { BleContext } from "../context/BleContext";

export function useBle() {
  const ble = useContext(BleContext);
  return ble;
}
