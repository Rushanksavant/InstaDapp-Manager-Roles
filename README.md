# InstaDapp Tasks

## Task2

### Objective:
To create a smart contract that could assign Manager Roles in DSA. A manager can only be assigned by DSA, and managers could have access to one or more connectors.
Also, managers can only interact with connectors using this contract, they wouldn't have access to DSA. 

### Methodology:
- Store manager and connector info in a nested mapping.
```solidity
mapping(uint64 => mapping(address => string[])) DSAmanagerConnectors;
mapping(uint64 => address[]) DSAmanagers;
```

- Adding manager for a list of connectors (will be called by DSA) 
    - check if DSA Id exist (using `accountID` from `InstaList`)
    - check if any duplicate connector name already present in: 
    ```solidity 
    DSAmanagerConnectors[DSA ID][manager address];
    ```
    - add unique connector names to: 
    `DSAmanagerConnectors[DSA ID][manager address];`

- Removing a manager (will be called by DSA) | input-> manager address
    - check length of `DSAmanagerConnectors[DSA ID][manager address]`
    - 
    ```solidity
    delete DSAmanagerConnectors[DSA ID][manager address]
    ```

- Interacting with connectors (will be called by managers) | input-> target, data
    - check length of `DSAmanagerConnectors[DSA ID][msg.sender]`
    - check if connector name mentioned in input is present in DSAmanagerConnectors[DSA ID][msg.sender]
    - get `cast()` function from `InstaImplementationM1`, and call it internally.

- Getter functions for `DSAmanagerConnectors` and `DSAmanagers`

