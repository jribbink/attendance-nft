import React, { useEffect, useState } from "react";
import { NativeBaseProvider } from "native-base";
import {
  BottomTabScreenProps,
  createBottomTabNavigator,
} from "@react-navigation/bottom-tabs";
import { NavigationContainer } from "@react-navigation/native";
import BadgesScreen from "./screens/BadgesScreen/BadgesScreen";
import SettingsScreen from "./screens/SettingsScreen/SettingsScreen";
import { SWRConfig } from "swr";
import { useBle } from "./hooks/useBle";
import BadgeModal from "./BadgeModal/BadgeModal";
import { Location } from "./models/Location";

export type BottomTabParams = {
  Badges: undefined;
  Settings: undefined;
};

export type BottomTabProps<T extends keyof BottomTabParams> =
  BottomTabScreenProps<BottomTabParams, T>;

const BottomTab = createBottomTabNavigator<BottomTabParams>();

export default function App() {
  const ble = useBle();
  const [modalLocation, setModalLocation] = useState<Location | null>(null);

  useEffect(() => {
    function listener(location: Location) {
      setModalLocation(location);
    }
    const subscription = ble?.addListener("locationFound", listener);

    return () => {
      subscription?.remove();
    };
  }, []);

  useEffect(() => {}, [ble]);

  return (
    <NativeBaseProvider>
      <SWRConfig>
        <NavigationContainer>
          <BottomTab.Navigator>
            <BottomTab.Screen name="Badges" component={BadgesScreen} />
            <BottomTab.Screen name="Settings" component={SettingsScreen} />
          </BottomTab.Navigator>
        </NavigationContainer>
        <BadgeModal
          location={modalLocation || undefined}
          onClose={() => setModalLocation(null)}
        ></BadgeModal>
      </SWRConfig>
    </NativeBaseProvider>
  );
}
