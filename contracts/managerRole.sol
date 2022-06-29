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

    // DSA => (manager address => array of connector names)
    mapping(address => mapping(address => string[])) DSAmanagerConnectors;
    // DSA => array of manager addresses
    mapping(address => address[]) DSAmanagers;

    mapping(address => mapping(string => bool)) managerConnectors;

    constructor(address _instaList, address _instaImplementationM1) {
        instaList = ListInterface(_instaList);
        instaImplementationM1 = ImplementationM1Interface(
            _instaImplementationM1
        );
    }

    function getDSA_ID(address _dsa) public returns (uint64) {
        return instaList.accountID(_dsa);
    }

    modifier ifManagerExist(address _manager) {
        address[] memory myManagers = DSAmanagers[msg.sender];

        for (uint256 i; i < myManagers.length; i++) {
            if (myManagers[i] == _manager) {
                revert("Address already manager");
            }
        }

        _;
    }

    modifier ifConnectorExist(address _manager, string[] memory _targets) {
        string[] memory managerConnectors = DSAmanagerConnectors[msg.sender][
            _manager
        ];

        for (uint256 i; i < _targets.length; i++) {
            string memory target = _targets[i];
            for (uint256 j; j < managerConnectors.length; j++) {
                if (
                    keccak256(abi.encodePacked((managerConnectors[j]))) ==
                    keccak256(abi.encodePacked((target)))
                ) {
                    revert("Target already exist");
                }
            }
        }

        _;
    }

    function addManager(address _manager, string[] memory _targets)
        external
        ifManagerExist(_manager)
    {
        DSAmanagers[msg.sender].push(_manager);

        for (uint256 i; i < _targets.length; i++) {
            DSAmanagerConnectors[msg.sender][_manager].push(_targets[i]);
        }
    }

    function removeManager(address _manager) external {}

    function addConnector(address _manager, string[] memory _targets)
        external
        ifManagerExist(_manager)
    {
        string[] memory managerConnectors = DSAmanagerConnectors[msg.sender][
            _manager
        ];
        string[] memory uniqueConnectors;

        for (uint256 i; i < _targets.length; i++) {
            string memory target = _targets[i];
            for (uint256 j; j < managerConnectors.length; j++) {
                if (
                    keccak256(abi.encodePacked((managerConnectors[j]))) ==
                    keccak256(abi.encodePacked((target)))
                ) {
                    break;
                }
                // uniqueConnectors.push(target);
            }
        }
    }

    function removeConnector(address _manager, string[] memory _targets)
        external
    {}
}
