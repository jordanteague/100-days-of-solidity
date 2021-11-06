// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./LexOwnable.sol";

/// @notice Ownable function pausing module.
abstract contract LexPausable is LexOwnable {
    event TogglePause(bool indexed paused);

    bool public paused;

    /// @notice Initialize pausing module.
    /// @param _paused If 'true', modified functions are paused.
    /// @param _owner Account to grant ownership of this module.
    constructor(bool _paused, address _owner) LexOwnable(_owner) {
        paused = _paused;
        emit TogglePause(_paused);
    }

    /// @notice Function pausing modifier that conditions functions to be called when `paused` is not enabled.
    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }

    /// @notice Toggle `paused` conditions on/off.
    /// @param _paused If 'true', modified functions are paused.
    function togglePause(bool _paused) external onlyOwner {
        paused = _paused;
        emit TogglePause(_paused);
    }
}
