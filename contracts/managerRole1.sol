//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ListInterface {
    function accountID(address _dsa) external returns (uint64);
}

interface ImplementationM1Interface {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

contract managerRole1 {
    ListInterface public immutable instaList;
    ImplementationM1Interface public immutable instaImplementationM1;

    constructor(address _instaList, address _instaImplementationM1) {
        instaList = ListInterface(_instaList);
        instaImplementationM1 = ImplementationM1Interface(
            _instaImplementationM1
        );
    }

    mapping(address => mapping(address => ConnectorsInfo))
        public dsaManagerConnectors;
    struct ConnectorsInfo {
        uint256 connectorCount;
        string[] allAddedConnectors;
        mapping(string => bool) connectorsEnabled;
    }

    mapping(address => address[]) dsaManagers;

    modifier dsaExists(address _dsa) {
        require(instaList.accountID(_dsa) > uint64(0));
        _;
    }

    modifier ifManagerExist(address _manager) {
        address[] memory myManagers = dsaManagers[msg.sender];

        for (uint256 i; i < myManagers.length; i++) {
            if (myManagers[i] == _manager) {
                revert("Address already manager");
            }
        }
        _;
    }

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

    function addManagerWithConnectors(
        address _manager,
        string[] memory _targets
    ) public dsaExists(msg.sender) ifManagerExist(_manager) {
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

    function addConnectors(address _manager, string[] memory _targets)
        public
        dsaExists(msg.sender)
        uniqueTargets(_manager, _targets)
    {
        bool flag;
        address[] memory allManagers = dsaManagers[msg.sender];
        for (uint256 j; j < allManagers.length; j++) {
            if (allManagers[j] == _manager) {
                flag = true;
                break;
            }
        }

        if (flag) {
            for (uint256 i; i < _targets.length; i++) {
                dsaManagerConnectors[msg.sender][_manager].connectorsEnabled[
                        _targets[i]
                    ] = true;

                dsaManagerConnectors[msg.sender][_manager]
                    .allAddedConnectors
                    .push(_targets[i]);

                dsaManagerConnectors[msg.sender][_manager].connectorCount++;
            }
        } else {
            revert("Manager not added, use addManagerWithConnectors");
        }
    }

    function removeManager(address _manager) public {
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

    function removeConnectors(address _manager, string[] memory _targets)
        public
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
}
