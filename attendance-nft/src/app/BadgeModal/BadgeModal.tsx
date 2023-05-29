import { Button, FormControl, Input, Modal, Text } from "native-base";
import { useBle } from "../hooks/useBle";
import { Location } from "../models/Location";

export default function BadgeModal({
  location,
  onClose,
}: {
  location?: Location;
  onClose: () => void;
}) {
  const ble = useBle();

  return (
    <Modal isOpen={!!location} onClose={onClose}>
      {!!location && (
        <Modal.Content maxWidth="400px">
          <Modal.CloseButton />
          <Modal.Header>You have unlocked a new badge!</Modal.Header>
          <Modal.Body>
            <Text>{location?.name}</Text>
          </Modal.Body>
          <Modal.Footer>
            <Button.Group space={2}>
              <Button variant="ghost" colorScheme="blueGray" onPress={onClose}>
                Ignore
              </Button>
              <Button
                onPress={async () => {
                  await ble?.claimBadge(location.id);
                  onClose();
                }}
              >
                Claim
              </Button>
            </Button.Group>
          </Modal.Footer>
        </Modal.Content>
      )}
    </Modal>
  );
}
