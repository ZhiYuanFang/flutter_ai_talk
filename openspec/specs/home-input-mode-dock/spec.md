## ADDED Requirements

### Requirement: Collapsed dock shows current mode as edge-flush semicircle

The home input mode dock SHALL display only the **current** input mode icon in a **semicircle** flush to a screen edge, with approximately half of the control visible inside the viewport.

#### Scenario: Voice mode collapsed on right edge

- **WHEN** the user is on the home screen with input mode `voice` and the dock is collapsed on the right edge
- **THEN** a semicircular control flush to the right edge shows the voice (microphone) icon with roughly half the circle visible on screen

#### Scenario: Mode icon updates after switch

- **WHEN** the user selects text input from the expanded dock
- **THEN** the collapsed semicircle shows the keyboard icon without requiring an app restart

### Requirement: Dock is draggable across the home body and snaps to four edges

The dock SHALL be draggable within the home screen body (history list and bottom input panel, respecting SafeArea) and SHALL snap to the nearest of top, bottom, left, or right on drag end.

#### Scenario: Snap to left after drag

- **WHEN** the user drags the dock and releases closer to the left edge than to other edges
- **THEN** the dock snaps to the left edge at the clamped along-edge position

#### Scenario: Along-edge position is clamped

- **WHEN** the user snaps the dock to any edge
- **THEN** the along-edge coordinate is clamped so the semicircle remains fully reachable and does not overlap system unsafe areas

### Requirement: Tap collapsed expands; select mode or outside tap collapses

The dock SHALL expand on tap while collapsed to show all available input modes; it SHALL collapse after the user selects a mode or taps outside the menu.

#### Scenario: Expand on tap

- **WHEN** the dock is collapsed and the user taps the semicircle
- **THEN** all available modes (voice, text, and buttons when supported) are shown

#### Scenario: Collapse after mode selection

- **WHEN** the expanded dock is visible and the user taps an available mode
- **THEN** the app switches input mode via existing channel selection logic and the dock collapses

#### Scenario: Collapse on outside tap

- **WHEN** the expanded dock is visible and the user taps outside the dock menu (on the configured dismiss region)
- **THEN** the dock collapses without changing the current mode

### Requirement: Expand layout follows docked edge orientation

The expanded menu SHALL lay out horizontally when docked to the top or bottom edge, and vertically when docked to the left or right edge, expanding toward the screen interior.

#### Scenario: Horizontal menu on bottom edge

- **WHEN** the dock is expanded while snapped to the bottom edge
- **THEN** mode options are arranged in a horizontal row above the semicircle

#### Scenario: Vertical menu on right edge

- **WHEN** the dock is expanded while snapped to the right edge
- **THEN** mode options are arranged in a vertical column to the left of the semicircle

### Requirement: Dock position is persisted across sessions

The app SHALL persist the snapped edge and along-edge position and restore them on the next home screen entry.

#### Scenario: Restore after cold start

- **WHEN** the user previously docked the switcher to the left edge at a saved along position and restarts the app
- **THEN** the home screen shows the collapsed dock at the same edge and along position

### Requirement: Dock integrates with existing input mode rules

The dock SHALL reuse existing input channel selection, persistence (`HomeInputChannelStore`), and availability rules (`_showButtonsInputMode`, Web `WEB_HOME_INPUT` / `_canSwitchInputMode`).

#### Scenario: Buttons hidden on Web text-only

- **WHEN** the home screen runs on Web with text-only input policy
- **THEN** the dock is not shown

#### Scenario: Buttons option on mobile

- **WHEN** the home screen runs on Android or iOS with buttons input supported
- **THEN** the expanded menu includes the buttons mode option

### Requirement: Fixed bottom toggle is removed

The home screen SHALL NOT show the legacy fixed three-icon toggle in the bottom input panel; text input SHALL NOT reserve extra right padding solely for that toggle.

#### Scenario: No fixed toggle in input panel

- **WHEN** the user views any input mode on a platform where the dock is shown
- **THEN** the bottom-right fixed icon row is absent and input layout uses symmetric horizontal padding where applicable

### Requirement: Expanded dock must not block core input gestures in the bottom panel

When expanded, the dismiss overlay SHALL NOT cover the bottom input panel region, so voice hold-to-talk and button-grid horizontal scrolling remain usable.

#### Scenario: Voice hold while expanded

- **WHEN** the dock is expanded and the user presses the voice orb in the bottom panel
- **THEN** voice recording can start without requiring the dock to collapse first

#### Scenario: Dismiss overlay covers history area

- **WHEN** the dock is expanded
- **THEN** taps on the history list area outside the menu collapse the dock
