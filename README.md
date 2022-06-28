# InstaDapp Tasks

## Task2

### Objective:
To create a smart contract that could assign Manager Roles in DSA. A manager can only be assigned by DSA, and managers could have access to one or more connectors.
Also, managers can only interact with connectors using this contract, they wouldn't have access to DSA. 

### Methodology:
- Store manager and connector info in a nested mapping.
mapping(uint64 => mapping(address => string[])) DSAmanagerConnectors

- Adding a manager for a list of connectors
    - check if DSA Id exist
    - check if ant duplicate connector name already present
    - add unique connector names to DSAmanagerConnectors

- Removing a manager
    - check length of DSAmanagerConnectors[DSA ID][manager address]
    - delete DSAmanagerConnectors[DSA ID][manager address]

- Interacting with connectors (will be called by managers)
    - check length of DSAmanagerConnectors[DSA ID][manager address]
    - check if connector name mentioned in input is present in DSAmanagerConnectors[DSA ID][manager address]
    -
    -
