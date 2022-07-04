//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./helpers.sol";

contract InstaManager is Helper {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(
        address _instaList,
        address _instaImplementationM1,
        address _instaConnectorV2
    ) Helper(_instaList, _instaImplementationM1, _instaConnectorV2) {}

    /**
     * @dev add a new manager for caller(DSA) along with allowed connectors
     * @param _manager address to be added as manager
     * @param _targets array of connector names to be enabled for new manager
     */
    function addManagerWithConnectors(
        address _manager,
        string[] memory _targets
    ) public dsaExists(msg.sender) verifyConnectors(_targets) {
        bool check = dsaManagers[msg.sender].contains(_manager);
        require(!check, "Manager already exist");

        dsaManagers[msg.sender].add(_manager);
        managerDSAs[_manager].add(msg.sender);

        for (uint256 i; i < _targets.length; i++) {
            dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                    _targets[i]
                ] = true;

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
        dsaExists(msg.sender)
        ifManagerExist(msg.sender, _manager)
        uniqueTargets(_manager, _targets)
    {
        for (uint256 i; i < _targets.length; i++) {
            dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                    _targets[i]
                ] = true;

            dsaManagerConnectors[msg.sender][_manager].connectorCount++;
        }
    }

    /**
     * @dev remove an address from manager role for given DSA
     * @param _manager address to be removed from manager role
     */
    function removeManager(address _manager)
        public
        dsaExists(msg.sender)
        ifManagerExist(msg.sender, _manager)
    {
        delete dsaManagerConnectors[msg.sender][_manager];

        dsaManagers[msg.sender].remove(_manager);
        managerDSAs[_manager].remove(msg.sender);
    }

    /**
     * @dev remove existing connectors for a manager of DSA
     * @param _manager address of manager for which connectors need to be disabled
     * @param _targets connector names to be disabled
     */
    function removeConnectors(address _manager, string[] memory _targets)
        public
        ifManagerExist(msg.sender, _manager)
        verifyConnectors(_targets)
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
        bool check = checkFunctionSig(_dsa, _targetNames, _datas);
        require(check, "Function signature denied");

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

    /**
     * @dev Add function signatures to be denied
     * @param _targetNames connector names for which the function signatures are to be denied
     * @param _datas function signatures
     */
    function denyFunctions(
        string[] calldata _targetNames,
        bytes[] calldata _datas
    ) public {
        for (uint256 i; i < _targetNames.length; i++) {
            bytes[] memory functionsDenied = deniedConnectorFunction[
                msg.sender
            ][_targetNames[i]];
            bool flag;

            for (uint256 j; j < functionsDenied.length; j++) {
                if (keccak256(functionsDenied[j]) == keccak256(_datas[i])) {
                    flag = true;
                    break;
                }
            }
            if (flag) {
                deniedConnectorFunction[msg.sender][_targetNames[i]].push(
                    _datas[i]
                );
            }
        }
    }

    /**
     * @dev Remove function signatures to be denied
     * @param _targetNames connector names for which the function signatures are denied, and need to be allowed
     * @param _datas function signatures
     */
    function removeDeniedFunctions(
        string[] calldata _targetNames,
        bytes[] calldata _datas
    ) public {
        for (uint256 i; i < _targetNames.length; i++) {
            bytes[] memory functionsDenied = deniedConnectorFunction[
                msg.sender
            ][_targetNames[i]];

            for (uint256 j; j < functionsDenied.length; j++) {
                if (keccak256(functionsDenied[j]) == keccak256(_datas[i])) {
                    deniedConnectorFunction[msg.sender][_targetNames[i]][
                        j
                    ] = deniedConnectorFunction[msg.sender][_targetNames[i]][
                        functionsDenied.length - 1
                    ];

                    deniedConnectorFunction[msg.sender][_targetNames[i]].pop();
                    break;
                }
            }
        }
    }
}
