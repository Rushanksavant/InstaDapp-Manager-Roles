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

interface InstaConnectorV2Interface {
    function isConnectors(string[] calldata _connectorNames)
        external
        view
        returns (bool isOk, address[] memory _connectors);
}
