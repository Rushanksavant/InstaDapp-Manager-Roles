//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces.sol";

contract Helper {
    ListInterface public immutable instaList;
    ImplementationM1Interface public immutable instaImplementationM1;

    constructor(address _instaList, address _instaImplementationM1) {
        instaList = ListInterface(_instaList);
        instaImplementationM1 = ImplementationM1Interface(
            _instaImplementationM1
        );
    }

    // DSA => manager address => ConnectorsInfo(connectors counter, connectors array, connectors mapping)
    mapping(address => mapping(address => ConnectorsInfo))
        public dsaManagerConnectors;
    struct ConnectorsInfo {
        uint256 connectorCount;
        string[] allAddedConnectors;
        mapping(string => bool) connectorsEnabled;
    }

    // DSA => manager address
    mapping(address => address[]) dsaManagers;

    // to check if DSA exist
    modifier dsaExists(address _dsa) {
        require(instaList.accountID(_dsa) > uint64(0));
        _;
    }

    // to check if given address exist as manager for given DSA
    modifier ifManagerExist(address _dsa, address _manager) {
        bool flag;
        address[] memory allManagers = dsaManagers[_dsa];
        for (uint256 j; j < allManagers.length; j++) {
            if (allManagers[j] == _manager) {
                flag = true;
                break;
            }
        }
        require(flag, "Manager does not exist");
        _;
    }

    // to check if any connector already enabled for given manager in DSA
    modifier uniqueTargets(address _manager, string[] memory _targets) {
        for (uint256 i; i < _targets.length; i++) {
            require(
                !dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                    _targets[i]
                ],
                "Target already exist"
            );
        }
        _;
    }
}
