## ADDED Requirements

### Requirement: Profile shows invite code entry
The client SHALL show the current user's invite code on the UCG profile ("我的") surface and SHALL open an invite detail screen on tap. The detail screen MUST explain that the code lets friends unlock invite-capable features (prediction +1 per redeem) and MUST list invitees with UCG nickname and redeem time from the cash invitees API.

#### Scenario: Open invite detail
- **WHEN** the owner taps the invite code on 我的
- **THEN** the app navigates to the invite detail with explanation and invitee list

#### Scenario: Empty invitees
- **WHEN** redeemedCount is 0
- **THEN** the list MAY be empty with a clear empty state
