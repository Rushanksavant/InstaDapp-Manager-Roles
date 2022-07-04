//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Helper {
    ListInterface public immutable instaList;
    ImplementationM1Interface public immutable instaImplementationM1;
    InstaConnectorV2Interface public immutable instaConnectorV2;

    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(
        address _instaList,
        address _instaImplementationM1,
        address _instaConnectorV2
    ) {
        instaList = ListInterface(_instaList);
        instaImplementationM1 = ImplementationM1Interface(
            _instaImplementationM1
        );
        instaConnectorV2 = InstaConnectorV2Interface(_instaConnectorV2);
    }

    // DSA => manager address => ConnectorsInfo(connectors counter, connectors mapping)
    mapping(address => mapping(address => ConnectorsInfo))
        public dsaManagerConnectors;
    struct ConnectorsInfo {
        uint256 connectorCount;
        mapping(string => bool) connectorsEnabled;
    }

    // DSA => manager addresses
    mapping(address => EnumerableSet.AddressSet) internal dsaManagers;
    // manager address => DSAs
    mapping(address => EnumerableSet.AddressSet) internal managerDSAs;

    // DSA => Connector => function sig[]
    mapping(address => mapping(string => bytes[]))
        public deniedConnectorFunction;

    // to check if DSA exist
    modifier dsaExists(address _dsa) {
        require(instaList.accountID(_dsa) != 0, "zero-caller: not-a-dsa");
        _;
    }

    // to check if given address exist as manager for given DSA
    modifier ifManagerExist(address _dsa, address _manager) {
        bool check = dsaManagers[_dsa].contains(_manager);
        require(check, "Manager does not exist");
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

    // to check if connector names are valid
    modifier verifyConnectors(string[] memory _targets) {
        (bool isOk, ) = instaConnectorV2.isConnectors(_targets);
        require(isOk, "One or more connector name(s) invalid");
        _;
    }

    // get all managers for caller(DSA)
    function getManagers() public view returns (address[] memory) {
        address[] memory array = new address[](
            managerDSAs[msg.sender].length()
        );

        for (uint256 i; i < managerDSAs[msg.sender].length(); i++) {
            array[i] = managerDSAs[msg.sender].at(i);
        }

        return array;
    }

    // get all DSAs for caller(manager address)
    function getDSAs() public view returns (address[] memory) {
        address[] memory array = new address[](
            dsaManagers[msg.sender].length()
        );

        for (uint256 i; i < dsaManagers[msg.sender].length(); i++) {
            array[i] = dsaManagers[msg.sender].at(i);
        }

        return array;
    }

    // to check if function sigs are allowed
    function checkFunctionSig(
        address _dsa,
        string[] calldata _targetNames,
        bytes[] calldata _datas
    ) internal view returns (bool) {
        bool flag;

        for (uint256 i; i < _datas.length; i++) {
            bytes[] memory functionsDenied = deniedConnectorFunction[_dsa][
                _targetNames[i]
            ];

            for (uint256 j; j < functionsDenied.length; j++) {
                if (keccak256(functionsDenied[j]) == keccak256(_datas[j])) {
                    flag = true;
                    break;
                }
            }

            if (flag) {
                break;
            }
        }

        return flag;
    }
}
