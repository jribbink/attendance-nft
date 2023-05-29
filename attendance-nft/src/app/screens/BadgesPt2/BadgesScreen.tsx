import { Badge } from "../../models/Badge";
import { useBadges } from "../../hooks/useBadges";
import { Box, Spinner } from "native-base";

export default function BadgesScreen() {
  const {data: badges} = useBadges();

  if(!badges) {
    return <Spinner size="lg"></Spinner>
  }

  return (
    <Box>
      {badges?.map((badge: Badge) => (
        <Box key={badge.id}>
          {badge.name}
        </Box>
      ))}
    </Box>
  );
}