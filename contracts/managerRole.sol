//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./helpers.sol";

contract InstaManager is Helper {
    constructor(address _instaList, address _instaImplementationM1)
        Helper(_instaList, _instaImplementationM1)
    {}

    /**
     * @dev add a new manager for caller(DSA) along with allowed connectors
     * @param _manager address to be added as manager
     * @param _targets array of connector names to be enabled for new manager
     */
    function addManagerWithConnectors(
        address _manager,
        string[] memory _targets
    ) public dsaExists(msg.sender) {
        address[] memory myManagers = dsaManagers[msg.sender];
        for (uint256 j; j < myManagers.length; j++) {
            if (myManagers[j] == _manager) {
                revert("Address already manager");
            }
        }

        dsaManagers[msg.sender].push(_manager);

        for (uint256 i; i < _targets.length; i++) {
            dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                    _targets[i]
                ] = true;

            dsaManagerConnectors[msg.sender][_manager].allAddedConnectors.push(
                _targets[i]
            );

            dsaManagerConnectors[msg.sender][_manager].connectorCount++;
        }
    }

    /**
     * @dev to add connectors to an existing manager of DSA
     * @param _manager address of manager
     * @param _targets array connectors to be enabled
     */
    function addConnectors(address _manager, string[] memory _targets)
        public
        ifManagerExist(msg.sender, _manager)
        uniqueTargets(_manager, _targets)
    {
        for (uint256 i; i < _targets.length; i++) {
            dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                    _targets[i]
                ] = true;

            dsaManagerConnectors[msg.sender][_manager].allAddedConnectors.push(
                _targets[i]
            );

            dsaManagerConnectors[msg.sender][_manager].connectorCount++;
        }
    }

    /**
     * @dev remove an address from manager role for given DSA
     * @param _manager address to be removed from manager role
     */
    function removeManager(address _manager)
        public
        ifManagerExist(msg.sender, _manager)
    {
        delete dsaManagerConnectors[msg.sender][_manager];

        address[] memory allManagers = dsaManagers[msg.sender];
        for (uint256 j; j < allManagers.length; j++) {
            if (allManagers[j] == _manager) {
                dsaManagers[msg.sender][j] = dsaManagers[msg.sender][
                    dsaManagers[msg.sender].length - 1
                ];
                dsaManagers[msg.sender].pop();
                break;
            }
        }
    }

    /**
     * @dev remove existing connectors for a manager of DSA
     * @param _manager address of manager for which connectors need to be disabled
     * @param _targets connector names to be disabled
     */
    function removeConnectors(address _manager, string[] memory _targets)
        public
        ifManagerExist(msg.sender, _manager)
    {
        for (uint256 i; i < _targets.length; i++) {
            require(
                dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                    _targets[i]
                ],
                "Target already disabled"
            );
            dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                    _targets[i]
                ] = false;
            dsaManagerConnectors[msg.sender][_manager].connectorCount--;
        }
    }

    /**
     * @dev function for managers to cast spells
     * @param _dsa address of DSA for which caller is manager
     * @param _targetNames connector names to cast spells for
     * @param _datas array of calldata
     */
    function cast(
        address _dsa,
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) public payable dsaExists(_dsa) ifManagerExist(_dsa, msg.sender) {
        for (uint256 i; i < _targetNames.length; i++) {
            require(
                dsaManagerConnectors[_dsa][msg.sender].connectorsEnabled[
                    _targetNames[i]
                ],
                "Target not enabled"
            );
        }

        instaImplementationM1.cast(_targetNames, _datas, _origin);
    }
}
