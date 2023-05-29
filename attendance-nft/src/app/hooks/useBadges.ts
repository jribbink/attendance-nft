import { useState } from "react";
import { Badge } from "../models/Badge";
import useSWR from "swr";
import * as fcl from "@onflow/fcl"

const KEY = () => 'badges';

export function useBadges() {
  return useSWR<Badge[]>(KEY(), async () => {
    const badgeIds = await fcl.query({
      cadence: `somequery`,
      args: (arg, t) => [arg("somearg", fcl.t.String)],
    })

    const badges = await Promise.all(
      badgeIds.map(async (id: string) => {
        const badge = await fcl.query({
          cadence: `somequery`,
          args: (arg, t) => [arg("somearg", fcl.t.String)],
        })
        return badge
      }
    ))

    return badges
  });
}