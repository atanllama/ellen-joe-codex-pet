# Labeled native-size resolution of blind direction warnings

Date: 2026-08-25  
Reviewer: independent Luna/max subagent (`task_9_labeled_warning_review`)  
Verdict: **PASS — accepted minor warnings**

The three isolated blind reviews produced zero hard-gate errors and zero unconfirmed hard pairs. Cardinal horizontal `090/270` and cardinal vertical `000/180` were correctly distinguished. Strict majority marked seven review-only intermediate axes ambiguous; labeled native-size and 16-frame loop review confirms that every affected pose remains in its intended quadrant without reversal:

- `022.5`: subtle screen-right component near the `000` vertical axis.
- `337.5`: subtle screen-left component that closes continuously into `000`.
- `112.5`: continuous transition from `090` into down-right.
- `135`: between right and down; horizontal component is weak but not reversed.
- `157.5`: near `180`, retaining a subtle screen-right component.
- `247.5`: between `225` and `270`, retaining a subtle down component.
- `292.5`: between `270` and `315`, retaining a subtle up component.

The clockwise loop has no visible snap, scale pop, identity change, or semantic reversal. Continuity diff diagnostics and the three heuristic alpha-hole warnings do not produce a visible defect at labeled native size. These warnings are accepted under the hatch-pet intermediate-direction policy and do not block packaging.

Evidence:

- `look-directions.png`
- `look-directions.gif`
- `look-directions-blind-consensus.json`
- `look-directions-blind-validation.json`
- `look-continuity.json`
- `direction-semantics.json`

