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

contract managerRole {
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
