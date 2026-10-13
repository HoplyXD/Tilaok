P05 visual rejection matrix (Godot 4.7.2-stable (official))
| Expected code | Actual code | Cell | Capture |
|---|---|---|---|

| unknown_variant | unknown_variant | (8, 5) | 01_rejection_unknown_variant_1920x1080.png |
  | Reason shown | Unknown item variant. Pick one from the approved list. |
  | Result | PASSED |

| variant_disabled | variant_disabled | (8, 5) | 02_rejection_variant_disabled_1920x1080.png |
  | Reason shown | This variant is not enabled in the current pool. |
  | Result | PASSED |

| rotation_unsupported | rotation_unsupported | (8, 5) | 03_rejection_rotation_unsupported_1920x1080.png |
  | Reason shown | This variant cannot face that way. Rotate to a supported direction. |
  | Result | PASSED |

| out_of_bounds | out_of_bounds | (32, 5) | 04_rejection_out_of_bounds_1920x1080.png |
  | Reason shown | Outside the arena. Move it inside the stage. (outside arena bounds) |
  | Result | PASSED |

| protected_spawn | protected_spawn | (4, 11) | 05_rejection_protected_spawn_1920x1080.png |
  | Reason shown | Spawn area is protected. Move it right of the spawn zone. (protected spawn zone) |
  | Result | PASSED |

| protected_goal | protected_goal | (28, 9) | 06_rejection_protected_goal_1920x1080.png |
  | Reason shown | Goal area is protected. Move it away from the flag platform. (protected goal zone) |
  | Result | PASSED |

| outside_build_region | outside_build_region | (6, 2) | 07_rejection_outside_build_region_1920x1080.png |
  | Reason shown | Outside the build region. Move it inside the green area. (outside build region) |
  | Result | PASSED |

| immutable_base | immutable_base | (6, 14) | 08_rejection_immutable_base_1920x1080.png |
  | Reason shown | Overlaps stage ground. Move it into open space. (immutable base geometry: arena.base_a) |
  | Result | PASSED |

| player_clearance | player_clearance | (8, 5) | 09_rejection_player_clearance_1920x1080.png |
  | Reason shown | A chicken is too close. Wait for them to move or pick another cell. (player clearance) |
  | Result | PASSED |

| item_overlap | item_overlap | (8, 5) | 10_rejection_item_overlap_1920x1080.png |
  | Reason shown | Overlaps another piece. Move it into a free cell. (overlaps p05_capture_fixture) |
  | Result | PASSED |

| persistent_cap | persistent_cap | (8, 5) | 11_rejection_persistent_cap_1920x1080.png |
  | Reason shown | Construction limit reached. Remove a piece first. |
  | Result | PASSED |

| invalid_region | invalid_region | (8, 5) | 12_rejection_invalid_region_1920x1080.png |
  | Reason shown | The region has no size. This is a definition defect. (region must have positive dimensions) |
  | Result | PASSED |
