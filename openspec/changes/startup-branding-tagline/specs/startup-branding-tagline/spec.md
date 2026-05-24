## ADDED Requirements

### Requirement: Startup overlay shows tagline below logo

The cold-start Flutter branding overlay SHALL display the tagline「最懂你的胖宝」directly below the pulsing logo, centered horizontally.

#### Scenario: Tagline visible during branding

- **WHEN** the app shows `StartupBrandingOverlay` after native splash is dismissed
- **THEN** the user sees the logo pulse and the tagline「最懂你的胖宝」beneath it on the brand background color

### Requirement: Tagline reveal completes within 1.5 seconds

The tagline SHALL animate once from smaller/lighter to larger/bolder within **1500ms**, then remain at the final style until the overlay fades out.

#### Scenario: Animation reaches final state at 1.5s

- **WHEN** the branding overlay has been visible for 1.5 seconds
- **THEN** the tagline has reached its maximum configured font size and weight and stops changing size or weight

#### Scenario: Tagline holds after reveal

- **WHEN** the branding overlay remains visible after 1.5 seconds and before fade-out begins
- **THEN** the tagline stays at the final size, weight, and color without repeating the reveal animation

### Requirement: Tagline color follows theme primary

The tagline color SHALL derive from `Theme.of(context).colorScheme.primary`, animating from a lower opacity to full opacity during the reveal.

#### Scenario: Primary color at end of reveal

- **WHEN** the tagline reveal animation completes
- **THEN** the tagline text uses the current theme primary color at full opacity

### Requirement: Tagline fades with overlay

The tagline SHALL fade out together with the existing startup overlay opacity animation without requiring a separate dismiss interaction.

#### Scenario: Overlay fade-out

- **WHEN** the app begins the startup overlay fade-out (`kStartupBrandingFadeOut`)
- **THEN** both the logo and tagline fade out with the overlay

### Requirement: Startup timing unchanged

The change MUST NOT alter native splash behavior, `kMinStartupBrandingDisplay`, or cold-start bootstrap routing.

#### Scenario: Minimum display duration preserved

- **WHEN** cold start runs with this change applied
- **THEN** the minimum branding overlay display duration remains 2400ms as before
